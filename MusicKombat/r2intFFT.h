//
//  r2intFFT.h
//  MonophonicPDA
//
//  Created by Ryan Hiroaki Tsukamoto on 9/10/11.
//  Copyright 2011 Miso Media Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct
{
	int real;
	int imag;
}	Int32Cplx;
typedef int PackedInt16Cplx;
PackedInt16Cplx* CreatePackedTwiddleFactors(int size);
void DisposePackedTwiddleFactors(PackedInt16Cplx* cosSinTable);
void generate_bro_lookup(int two_exp, int* p_result);//store (interleaved) pairs of indices that need their values swapped
void bro_with_lookup(Int32Cplx* ioCplxData, int* interleaved_bro_lookup, int N);//perform in-place bro with above structure with a bit twiddle
void radix2_int32cplx_pfft(Int32Cplx* xX, int N, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N, int start_span, int end_span);
void radix2_int32cplx_fft(Int32Cplx* xX, int N, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
int NormDoubleToInt16(double x);
void radix2_int32cplx_fft_2(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
void radix2_int32cplx_fft_4(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
void radix2_int32cplx_fft_8(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
void radix2_int32cplx_fft_16(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
void radix2_int32cplx_fft_32(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
void radix2_int32cplx_fft_64(Int32Cplx* xX, const PackedInt16Cplx* twiddles, int* interleaved_bro_lookup, int bro_N);
