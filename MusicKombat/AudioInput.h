//
//  AudioInput.h
//  MonophonicPDA
//
//  Created by Ryan Hiroaki Tsukamoto on 9/10/11.
//  Copyright 2011 Miso Media Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAStreamBasicDescription.h"

typedef struct
{
	bool note_found;
	int	note;
}	MPDA_RESULT;

MPDA_RESULT make_MPDA_RESULT(bool n_f, int n);

@protocol MPDADelegateProtocol

-(void)pitchDetected:(MPDA_RESULT)result;

@end


int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProcm, CAStreamBasicDescription& outFormat);
void SilenceData(AudioBufferList *inData);

@interface AudioInput : NSObject
{
	AudioUnit					rioUnit;
	int							unitIsRunning;
	CAStreamBasicDescription	thruFormat;
	AURenderCallbackStruct		inputProc;
}
@property (nonatomic, assign)	AudioUnit				rioUnit;
@property (nonatomic, assign)	int						unitIsRunning;
@property (nonatomic, assign)	AURenderCallbackStruct	inputProc;

- (id)initWithDelegate:(id <MPDADelegateProtocol>)delegate;

@end
