#pragma once

#include "Plugin.h"
#import <AudioToolbox/AudioToolbox.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "CAAudioUnit.h"

#include "DCAudioRecorder.h"

#define NUMSEGMENTS 20

struct segment {
	float y;
	float v;
	float a;
};

@interface WaveObject : NSObject {
	ExtAudioFileRef audioFile;
	float *audioBuffer;
	
	UInt64 numFrames;
	
	float avgMin, avgMax;
	
	segment segments[NUMSEGMENTS];
	
	ofSoundPlayer sound;
	
	NSMutableArray * waves;
	
	bool liveAudio;
	DCAudioRecorder * audioRecorder;
	AudioBufferList liveBuffer;
	vector<float> simplifiedCurve;
	vector<float> softCurve;
	
	int nBandsToGet;
	
}

@property (readonly) float avgMin;
@property (readonly) float avgMax;;
@property (retain, readwrite) NSMutableArray * waves;

-(void) updateWithSpeed:(float)speed;
-(void) draw;
-(void) loadAudio:(NSString*)name;
-(void) loadMic;
-(float *) getWaveData;
-(vector<float>* ) simplifiedCurve;
-(vector<float>* ) softCurve;

-(segment*)segments;

@end
