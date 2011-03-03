//
//  Wave.h
//  malpais
//
//  Created by ole kristensen on 11/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//
#pragma once

#include "Plugin.h"
#include "AudioDeviceList.h"
#include "WaveObject.h"
#include "fft.h"

#define NUM_VOICES 8
#define NUM_BANDS 7
#define MAX_RESOLUTION 128
#define MIDI_CHANNEL 1


@interface Wave : ofPlugin {
	
	WaveObject * liveVoice;
	
	NSMutableArray * voiceWaveForms;
	
	float voiceSourceWaves[NUM_VOICES+1][NUM_BANDS][MAX_RESOLUTION];
	
	float voiceUpdateTimes[NUM_VOICES+1];
	
	float frameRateDeltaTime;
	float lastUpdateTime;
	
	fft		liveFFT;
	int liveSamples;
	
	float magnitude[2048];
	float phase[2048];
	float power[2048];
	float avg_power;		
	
	IBOutlet NSPopUpButton *		mInputDevices;
	//	AudioDeviceList *				mInputDeviceList;
	//	AudioDeviceID					inputDevice;
	
}

- (IBAction)inputDeviceSelected:(id)sender;
- (NSMutableArray*) getWaveFormWithIndex:(int)index 
							   amplitude:(float)amplitude 
							  driftSpeed:(float)driftSpeed
							   smoothing:(float)smoothing
							   freqeuncy:(float)frequency
								  random:(float)randomFactor
								  offset:(float)offset
						 withFormerArray:(NSMutableArray*)formerArray;

- (NSMutableArray*) getWaveFormBandsWithIndex:(int)index 
								amplitude:(float)amplitude 
							   driftSpeed:(float)driftSpeed
								smoothing:(float)smoothing
								freqeuncy:(float)frequency
								   random:(float)randomFactor								  
								   offset:(float)offset
						  withFormerArray:(NSMutableArray*)formerArray;


@end
