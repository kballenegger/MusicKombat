//
//  AudioInput.m
//  MonophonicPDA
//
//  Created by Ryan Hiroaki Tsukamoto on 9/10/11.
//  Copyright 2011 Miso Media Inc. All rights reserved.
//

#import "AudioInput.h"
#import "AudioUnit/AudioUnit.h"
#import "CAXException.h"
#import <math.h>
#import "r2intFFT.h"

#define SNAC_buf_length 1024
#define SNAC_log2_buf_length 10
int					SNAC_resamp_carry = 0;
int					SNAC_resamp_factor = 2;
int					SNAC_coordinate = 0;
double				filtered_SNAC_results[SNAC_buf_length];
const double		filtered_SNAC_filter_coeff = 0.1875;
int					resamp_signal[256];

Int32Cplx			SNAC_xXs[2][SNAC_buf_length];
int					SNAC_buf_idx = 0;				//which buffer are we filling?  run computations on the other buffer.
double				SNAC_x_xs[2][SNAC_buf_length];		//holds the squares of the samples
int					SNAC_xX_idx = 0;
bool				SNAC_found_pitch = false;
int					SNAC_note;
double				SNAC_SNAC_pitch = 0.0;//number of semitones sharp/flat from middle C//SNAC_note
double				SNAC_m[SNAC_buf_length];
double				SNAC_results[SNAC_buf_length];
//GLfloat				SNAC_result_verts[2 * SNAC_buf_length];
int					SNAC_SNAC_peak_idxs;
double				SNAC_peak_vals;
const double		SNAC_abs_cutoff = 0.75;
const double		SNAC_peak_ratio_cutoff = 0.9375;
const int			SNAC_num_scored_notes = 72;
double				SNAC_note_scores[SNAC_num_scored_notes];//from -42 to +54
const int			SNAC_low_note = -42;

PackedInt16Cplx*		SNAC_twiddles;
int*					SNAC_bro_lookup;
int						SNAC_bro_N;

double						A4_in_Hz = 440.0;
Float64				hwSampleRate;
bool				analysis_ready		=	false;
double				audio_input_vals[256];
bool				reading_tuner;

id PDA_delegate;

MPDA_RESULT make_MPDA_RESULT(bool n_f, int n)
{
	MPDA_RESULT result;
	result.note_found = n_f;
	result.note = n;
	return result;
}

int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat)
{	
	try
	{
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		XThrowIfError(AudioComponentInstanceNew(comp, &inRemoteIOUnit), "couldn't open the remote I/O unit");
		UInt32 one = 1;
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "couldn't enable input on the remote I/O unit");
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc)), "couldn't set remote i/o render callback");
        outFormat.SetAUCanonical(2, false);
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's output client format");
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's input client format");
		XThrowIfError(AudioUnitInitialize(inRemoteIOUnit), "couldn't initialize the remote I/O unit");
	}
	catch(CAXException &e)
	{
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 1;
	}
	catch(...)
	{
		fprintf(stderr, "An unknown error occurred\n");
		return 1;
	}	
	return 0;
}
void SilenceData(AudioBufferList *inData)
{
	for(UInt32 i=0; i < inData->mNumberBuffers; i++)	memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}


@interface AudioInput () {
@private
}
-(void)setup;
@end

@implementation AudioInput
@synthesize rioUnit;
@synthesize unitIsRunning;
@synthesize inputProc;

void rioInterruptionListener(void* inClientData, UInt32 inInterruption);
void rioInterruptionListener(void* inClientData, UInt32 inInterruption)
{
	NSLog(@"Session interrupted! --- %@ ---", inInterruption == kAudioSessionBeginInterruption ? @"Begin Interruption" : @"End Interruption");
	AudioInput* THIS = (AudioInput*)inClientData;
	if(inInterruption == kAudioSessionEndInterruption)
	{
		AudioSessionSetActive(true);
		AudioOutputUnitStart(THIS->rioUnit);
	}
	if(inInterruption == kAudioSessionBeginInterruption)	AudioOutputUnitStop(THIS->rioUnit);
}
void propListener(void* inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData);
void propListener(void* inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData)
{
	AudioInput* THIS = (AudioInput*)inClientData;
	if(inID == kAudioSessionProperty_AudioRouteChange)
	{
		try
		{
			XThrowIfError(AudioComponentInstanceDispose(THIS->rioUnit), "couldn't dispose remote i/o unit");		
			SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat);
			UInt32 size = sizeof(hwSampleRate);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get new sample rate");
			XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
			CFStringRef newRoute;
			size = sizeof(CFStringRef);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute), "couldn't get new audio route");
			if(newRoute)
			{	
				CFShow(newRoute);
				if (CFStringCompare(newRoute, CFSTR("Headset"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					NSLog(@"new route is headset");
				}
				else if (CFStringCompare(newRoute, CFSTR("Receiver"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					NSLog(@"new route is receiver");
				}			
				else
				{
					NSLog(@"new route is i dunno");
				}
			}
		}
		catch(CAXException e)
		{
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
	}
}
static OSStatus	PerformThru(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
	AudioInput* THIS = (AudioInput*)inRefCon;
	OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if(err)
	{
		NSLog(@"PerformThru: error %d\n", (int)err);
		return err;
	}
	SInt8* data_ptr = (SInt8*)(ioData->mBuffers[0].mData);
	int num_samps = 256 / SNAC_resamp_factor;
	int SNAC_half_len = SNAC_buf_length / 2;
	if(SNAC_resamp_factor == 1)	for(int i = 0; i < 256; i++)
	{
		int this_sample = data_ptr[2];
		data_ptr += 4;
		resamp_signal[i] = this_sample;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i].real = 64 * this_sample;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i].imag = 0;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i + SNAC_half_len].real = SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i + SNAC_half_len].imag = 0;
		SNAC_x_xs[SNAC_buf_idx][SNAC_xX_idx + i] = 4096 * this_sample * this_sample;
	}
	else if(SNAC_resamp_factor == 2)	for(int i = 0; i < 128; i++)
	{
		int this_sample = data_ptr[2] + data_ptr[6];
		data_ptr += 8;
		resamp_signal[i] = this_sample;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i].real = 64 * this_sample;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i].imag = 0;
		SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i + SNAC_half_len].real = SNAC_xXs[SNAC_buf_idx][SNAC_xX_idx + i + SNAC_half_len].imag = 0;
		SNAC_x_xs[SNAC_buf_idx][SNAC_xX_idx + i] = 4096 * this_sample * this_sample;
	}
	SNAC_xX_idx += num_samps;
	if(SNAC_xX_idx == SNAC_half_len)
	{
		SNAC_buf_idx = 1 - SNAC_buf_idx;
		SNAC_coordinate = 0;
		SNAC_xX_idx = 0;
	}
	else
	{
		SNAC_coordinate++;
	}
	switch(SNAC_coordinate)
	{
		case 0:
		{
			double* SNAC_x_x = SNAC_x_xs[1 - SNAC_buf_idx];
			SNAC_m[0] = 0.0;
			for(int i = 0; i < SNAC_half_len; i++)	SNAC_m[0] += SNAC_x_x[i];
			SNAC_m[0] *= 2.0;
			radix2_int32cplx_pfft(SNAC_xXs[1 - SNAC_buf_idx], SNAC_buf_length, SNAC_twiddles, SNAC_bro_lookup, SNAC_bro_N, 1, 32);
			break;
		}
		case 1:
		{
			radix2_int32cplx_pfft(SNAC_xXs[1 - SNAC_buf_idx], SNAC_buf_length, SNAC_twiddles, SNAC_bro_lookup, SNAC_bro_N, 32, SNAC_buf_length);
			break;
		}
		case 2:
		{
			Int32Cplx* SNAC_xX = SNAC_xXs[1 - SNAC_buf_idx];
			double* SNAC_x_x = SNAC_x_xs[1 - SNAC_buf_idx];
			int half_n_minus_1 = SNAC_half_len - 1;
			int half_n_minus_i = half_n_minus_1;
			for(int i = 0; i < half_n_minus_1; i++)
			{
				SNAC_m[i + 1] = SNAC_m[i] - SNAC_x_x[i] - SNAC_x_x[half_n_minus_i];
				half_n_minus_i--;
			}
			for(int i = 0; i < SNAC_buf_length; i++)
			{
				SNAC_xX[i].real = SNAC_xX[i].real * SNAC_xX[i].real + SNAC_xX[i].imag * SNAC_xX[i].imag;
				SNAC_xX[i].imag = 0;
			}
			radix2_int32cplx_pfft(SNAC_xX, SNAC_buf_length, SNAC_twiddles, SNAC_bro_lookup, SNAC_bro_N, 1, 32);
			break;
		}
		case 3:
		{
			radix2_int32cplx_pfft(SNAC_xXs[1 - SNAC_buf_idx], SNAC_buf_length, SNAC_twiddles, SNAC_bro_lookup, SNAC_bro_N, 32, SNAC_buf_length);
			Int32Cplx* SNAC_xX = SNAC_xXs[1 - SNAC_buf_idx];
			double norm_factor = SNAC_xX[0].real == 0 ? 1.0 : SNAC_m[0] / SNAC_xX[0].real;
			for(int i = 0; i < SNAC_half_len; i++)
			{
				double this_result = norm_factor * SNAC_xX[i].real / SNAC_m[i];
				SNAC_results[i] = this_result;
				filtered_SNAC_results[i] += filtered_SNAC_filter_coeff * (this_result - filtered_SNAC_results[i]);
				if(filtered_SNAC_results[i] != filtered_SNAC_results[i])	filtered_SNAC_results[i] = 0;
			}
			bool in_peak = false;
			int SNAC_peak_idxs[64];
			int num_peaks = 0;
			int max_peak_idx = 0;
			double max_peak = 0.0;
			int this_peak_idx = 0;
			double this_peak_max = 0;
			memset(SNAC_peak_idxs, 0, 64);
			for(int i = 1; i < 2 * SNAC_half_len / 3 && num_peaks < 64; i++)
			{
				if(in_peak)
				{
					double this_SNAC = filtered_SNAC_results[i];
					if(max_peak < this_SNAC)
					{
						max_peak_idx = i;
						this_peak_idx = i;
						max_peak = this_SNAC;
						this_peak_max = this_SNAC;
					}
					else if(this_SNAC < 0)
					{
						in_peak = false;
						if(this_peak_max <= 1.0)	SNAC_peak_idxs[num_peaks++] = this_peak_idx;
					}
					else if(this_peak_max < this_SNAC)
					{
						this_peak_idx = i;
						this_peak_max = this_SNAC;
					}
				}
				else
				{
					if(filtered_SNAC_results[i - 1] <= 0 && filtered_SNAC_results[i] > 0)
					{
						double this_SNAC = filtered_SNAC_results[i];
						in_peak = true;
						this_peak_idx = i;
						this_peak_max = this_SNAC;
						if(max_peak < this_SNAC)
						{
							max_peak_idx = i;
							max_peak = this_SNAC;
						}
					}
				}
			}
			for(int i = 0; i < num_peaks; i++)
			{
				if(filtered_SNAC_results[SNAC_peak_idxs[i]] < SNAC_abs_cutoff || filtered_SNAC_results[SNAC_peak_idxs[i]] < max_peak * SNAC_peak_ratio_cutoff)
				{
					for(int j = i--; j < num_peaks - 1; j++)	SNAC_peak_idxs[j] = SNAC_peak_idxs[j + 1];
					num_peaks--;
				}
			}
			int i_note;
			int octave = 0;
			double pitch;
			if(num_peaks > 0)
			{
				int peak_ind = SNAC_peak_idxs[0];
				double y_pos = SNAC_results[peak_ind] - SNAC_results[peak_ind + 1];
				double y_neg = SNAC_results[peak_ind] - SNAC_results[peak_ind - 1];
				double tau0 = peak_ind + 0.5 * (y_neg - y_pos) / (y_neg + y_pos);
				pitch = 12.0 * (log(hwSampleRate / (tau0 * SNAC_resamp_factor)) - log(A4_in_Hz * pow(0.5, 0.75))) / log(2.0);
				double shifted_pitch = pitch + 0.5;
				while(shifted_pitch < 0)
				{
					shifted_pitch += 12.0;
					octave--;
				}
				while(shifted_pitch >= 12.0)
				{
					shifted_pitch -= 12.0;
					octave++;
				}
				i_note = (int)shifted_pitch;
				int i_pitch = i_note + 12 * octave;
				SNAC_note_scores[i_pitch - SNAC_low_note] += 1.0;
			}
			double max_score = 0.0;
			int max_idx = -1;
			for(int i = 0; i < SNAC_num_scored_notes; i++)
			{
				if(max_score < SNAC_note_scores[i] && 1.25 < SNAC_note_scores[i])
				{
					max_score = SNAC_note_scores[i];
					max_idx = i;
				}
				SNAC_note_scores[i] *= 0.9375;
			}
			if(max_idx == -1)
			{
				if(SNAC_found_pitch)	[PDA_delegate pitchDetected:make_MPDA_RESULT(false, 420)];
				SNAC_found_pitch = false;
			}
			else
			{
				if(!SNAC_found_pitch || SNAC_note != max_idx + SNAC_low_note)
				{
					//set_SNAC_note(max_idx + SNAC_low_note);
					SNAC_note = SNAC_low_note + max_idx;
					[PDA_delegate pitchDetected:make_MPDA_RESULT(true, SNAC_note)];
					if(!SNAC_found_pitch)
					{
						reading_tuner = true;
						SNAC_SNAC_pitch = pitch;
					}
					else
					{
						reading_tuner = false;
					}
				}
				else	if(SNAC_SNAC_pitch != SNAC_SNAC_pitch)
				{
					SNAC_SNAC_pitch = pitch;
					reading_tuner = true;
				}
				else
				{
					const double SNAC_pitch_filter_coeff = 0.03125;
					SNAC_SNAC_pitch += SNAC_pitch_filter_coeff * (pitch - SNAC_SNAC_pitch);
					reading_tuner = true;
				}
				SNAC_note = max_idx + SNAC_low_note;
				SNAC_found_pitch = true;
			}
			break;
		}
	}
	SilenceData(ioData);
	return err;
}

-(id)initWithDelegate:(id <MPDADelegateProtocol>)d
{
	if(self = [super init])
	{
		PDA_delegate = d;
		[self setup];
		inputProc.inputProc = PerformThru;
		inputProc.inputProcRefCon = self;
		try
		{
			XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");
			XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
			UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
			XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
			XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self), "couldn't set property listener");
			Float32 preferredBufferSize = .005;
			XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
			UInt32 size = sizeof(hwSampleRate);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
			XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
			UInt32 maxFPS;
			size = sizeof(maxFPS);
			XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
			//			oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
			XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
			size = sizeof(thruFormat);
			XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
			unitIsRunning = 1;
		}
		catch(CAXException &e)
		{
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
			unitIsRunning = 0;
		}
		catch(...)
		{
			fprintf(stderr, "An unknown error occurred\n");
			unitIsRunning = 0;
		}
		NSLog(@"Got through the try block.  Hardware sample rate: %f", hwSampleRate);
	}
	return self;
}

-(void)setup
{
	SNAC_twiddles = CreatePackedTwiddleFactors(SNAC_buf_length);
	SNAC_bro_lookup = (int*)malloc(sizeof(int) * SNAC_buf_length);
	memset(SNAC_bro_lookup, 0, sizeof(int) * SNAC_buf_length);
	generate_bro_lookup(SNAC_log2_buf_length, SNAC_bro_lookup);
	SNAC_bro_N = 0;
	while(SNAC_bro_lookup[SNAC_bro_N] != 0)	SNAC_bro_N++;
	SNAC_bro_N >>= 1;
	for(int i = 0; i < SNAC_buf_length; i++)
	{
		filtered_SNAC_results[i] = 0;
	}
}
@end
