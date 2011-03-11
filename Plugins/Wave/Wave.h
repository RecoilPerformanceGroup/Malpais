//
//  Wave.h
//  malpais
//
//  Created by ole kristensen on 11/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//
#pragma once

#include "Plugin.h"
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include "CARingBuffer.h"
#include "AudioDevice.h"
#include "CAStreamBasicDescription.h"
#include "AudioDeviceList.h"
#include "WaveObject.h"
#include "fft.h"

#define NUM_VOICES 8
#define NUM_BANDS 7
#define MAX_RESOLUTION 128
#define MIDI_CHANNEL 1


@interface Wave : ofPlugin {
	
	WaveObject * liveVoice;
	
	NSMutableArray * voices;

	float frameRateDeltaTime;
	float lastUpdateTime;
	
	fft		liveFFT;
	int liveSamples;
	
	float magnitude[2048];
	float phase[2048];
	float power[2048];
	float avg_power;		
	
	IBOutlet NSPopUpButton *		mInputDevices;
	AudioDeviceList *				mInputDeviceList;
	AudioDeviceID					inputDevice;
	
}

- (IBAction)inputDeviceSelected:(id)sender;

- (NSDictionary*) getVoiceWithIndex:(int)index 
						  amplitude:(float)amplitude 
						   preDrift:(float)preDrift
						  postDrift:(float)postDrift
					  smoothingRise:(float)smoothingRise
					  smoothingFall:(float)smoothingFall
						  smoothing:(float)smoothing
						  freqeuncy:(float)frequency
						 resolution:(int)resolution
							 random:(float)randomFactor
							 offset:(float)offset
			   withFormerDictionary:(NSDictionary*)formerDictionary;


@end
