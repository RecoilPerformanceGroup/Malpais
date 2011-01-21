//
//  WaveObject.mm
//  malpais
//
//  Created by Jonas Jongejan on 20/01/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#import "WaveObject.h"

#define BUFFER_SIZE 44100
Float64 kGraphSampleRate=44100.; // Our internal sample rate


@implementation WaveObject
@synthesize y, avgMin, avgMax, simplifiedCurve;

-(id) init{		
	if([super init]){
		y = ofRandom(0, 1);
		i = 0;
	}
	return self;
}

-(void) updateWithSpeed:(float)speed{
	i +=kGraphSampleRate*speed;
	if(i > numFrames)
		i = 0;
	
	if([self getWaveData][0] < 0){
		avgMin += ([self getWaveData][0] - avgMin)*0.1;
	} else {
		avgMax += ([self getWaveData][0] - avgMax)*0.1;		
	}
	
	simplifiedCurve.push_back(sin(i/kGraphSampleRate));
	if(simplifiedCurve.size() > 500)
		simplifiedCurve.erase(simplifiedCurve.begin()+1);
}

-(float *) getWaveData{
	return audioBuffer + i;
}

-(void) loadAudio:(NSString *)name{
	CFURLRef url = (CFURLRef) [[NSURL alloc] initFileURLWithPath:name];
	OSStatus status = ExtAudioFileOpenURL(url, &audioFile);
	if(status){
		NSLog(@"Load audio failed %@: %i",url,status);
		return;
	}
	
	UInt32 propSize;	
	CAStreamBasicDescription clientFormat;
	propSize = sizeof(clientFormat);

	// Determine the input file's format
	status = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
	if(status){
		NSLog(@"Not able to get properties about audio %@: %i",url,status);
		return;
	}
	
	
	clientFormat.mSampleRate = kGraphSampleRate;
	clientFormat.SetAUCanonical(2, true);
	
	
	propSize = sizeof(clientFormat);
	status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
	if(status){
		NSLog(@"Not able to set properties about audio %@: %i",url,status);
		return;
	}
	
	numFrames = 0;
	propSize = sizeof(UInt64);
	status = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
	if (status) {
		printf("couldn't get file length\n");
		return;
	}
	
	double rateRatio = kGraphSampleRate / clientFormat.mSampleRate;
	numFrames = (UInt32)(numFrames * rateRatio); // account for sample rate conversion
	cout<<"File length: "<<numFrames<<" packets"<<endl;

	UInt32 samples = numFrames*2;//<<1; // 2 channels (samples) per frame

	
	audioBuffer = (float*)calloc(samples, sizeof(Float32));

	
	AudioBufferList conversionBuffer;
	conversionBuffer.mNumberBuffers = 1;
	conversionBuffer.mBuffers[0].mNumberChannels = 2;
	conversionBuffer.mBuffers[0].mData = audioBuffer;
	conversionBuffer.mBuffers[0].mDataByteSize = samples * sizeof(Float32);	
	

	
	UInt32 loadedPackets = numFrames;
	status = ExtAudioFileRead(audioFile, &loadedPackets, &conversionBuffer);
	if(status){
		NSLog(@"Read audio failed %@: %i",url,status);
		return;
	} 
	cout<<"Loaded "<<loadedPackets<<" packets"<<endl;
	
	ExtAudioFileDispose(audioFile);
	
}
@end
