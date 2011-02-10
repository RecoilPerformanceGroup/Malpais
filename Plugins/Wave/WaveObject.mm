//
//  WaveObject.mm
//  malpais
//
//  Created by Jonas Jongejan on 20/01/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#import "WaveObject.h"

#define BUFFER_SIZE 10000
Float64 kGraphSampleRate=44100.; // Our internal sample rate


@implementation WaveObject
@synthesize avgMin, avgMax, waves;

-(id) init{		
	if([super init]){
		
		float y = ofRandom(0, 1);
		for(int i=0;i<NUMSEGMENTS;i++){
			segments[i].y = y+ofRandom(-0.01, 0.01);
			segments[i].v = 0;
		}
		nBandsToGet = 128;
	}
	return self;
}

-(float) elevationAtPoint:(float)_y{
	return pow(2,_y*5-5);
	//return _y;
}

-(segment*)segments{
	return segments;
}

-(vector<float>* ) simplifiedCurve{
	return &simplifiedCurve;
}

-(void) updateWithSpeed:(float)speed{
	if(liveAudio){
		SInt64 beginTime, endTime;
		audioRecorder->mBuffer->GetTimeBounds(beginTime, endTime);
		OSStatus status = audioRecorder->mBuffer->Fetch(&liveBuffer, BUFFER_SIZE, beginTime, true);
		
		simplifiedCurve.push_back([self getWaveData][-10]);
		simplifiedCurve.push_back([self getWaveData][-110]);
		simplifiedCurve.push_back([self getWaveData][-220]);
		simplifiedCurve.push_back([self getWaveData][-330]);
		while(simplifiedCurve.size() > 1000)
			simplifiedCurve.erase(simplifiedCurve.begin());
	} else {
		ofSoundUpdate();	

		float * val = ofSoundGetSpectrum(nBandsToGet);		// request values for fft
		for (int i = 0;i < nBandsToGet; i++){
			
			val[i];
						
		}
		
	}

	
	//	cout<<beginTime<<"  "<<endTime<<"   "<<status<<endl;
	/*	i +=kGraphSampleRate*speed;
	 if(i > numFrames)
	 i = 0;
	 */	
	/*if([self getWaveData][0] < 0){
	 avgMin += ([self getWaveData][0] - avgMin)*0.1;
	 } else {
	 avgMax += ([self getWaveData][0] - avgMax)*0.1;		
	 }
	 */
	
	//Reset segments
	for(int i=0;i<NUMSEGMENTS;i++){
		segments[i].a = 0;
	}
	
	//New wave effect
	for(int i=0;i<NUMSEGMENTS;i++){
		if(segments[i].y < -0.2){
			for(int j=0;j<NUMSEGMENTS;j++){
				segments[j].a = 2;
			}
		}
	}
	
	//Internal "spring" effect (will straighten out)
	float springForce = 0.1; 
	for(int i=0;i<NUMSEGMENTS;i++){
		if(i > 0)
			segments[i].a += springForce*(segments[i-1].y-segments[i].y);
		if(i < NUMSEGMENTS-1)
			segments[i].a += springForce*(segments[i+1].y-segments[i].y);
	}
	
	//Eleveation
	float elevationForce = 0.02;
	for(int i=0;i<NUMSEGMENTS;i++){
		segments[i].a += -elevationForce*[self elevationAtPoint:segments[i].y];
	}
	
	//Push to other waves
	float wavePushForce = 0.05;	
	for(WaveObject * wave in waves){
		if(wave != self){
			for(int i=0;i<NUMSEGMENTS;i++){
				float a = fabs([self segments][i].y - [wave segments][i].y);
				if(a > 0 && a < 1){
					a = -log(a);
					
					if([self segments][i].y > [wave segments][i].y)
						segments[i].a += a*wavePushForce;
					else 
						segments[i].a -= a*wavePushForce;
				}
			}
		}
	}
	
	//Side push
	for(int i=0;i<NUMSEGMENTS;i++){
		if(segments[i].y < -0){
			segments[i].y = 0;
		}
		if(segments[i].y > 1){
			segments[i].y = 1;
		}
		
	}
	
	//Pull other waves 
	float wavePullForce = 0.0;	
	for(WaveObject * wave in waves){
		if(wave != self){
			for(int i=0;i<NUMSEGMENTS;i++){
				float a = 1 - fabs([self segments][i].y - [wave segments][i].y);
				segments[i].a += a*wavePullForce* ([self segments][i].v - [wave segments][i].v );
			}
		}
	}
	
	//Apply
	for(int i=0;i<NUMSEGMENTS;i++){
		segments[i].v += segments[i].a * 0.1;
		//if(segments[i].v > 0)
		segments[i].v *= 0.99;
		//	else 
		//		segments[i].v *= 0.95;
		
		segments[i].y += segments[i].v * speed * 1;
	}
	
	/*
	 v -= [self elevationAtPoint:y];
	 v  *= 0.99;
	 y += v*speed*0.1;*/
}



-(float *) getWaveData{
	//	return audioBuffer + i;
	//cout<<sound.getPosition()<<"  "<<sound.length<<"   "<<lroundf(sound.getPosition()*sound.length)<<"    "<<i<<endl;
	if(liveAudio){
		return audioBuffer+BUFFER_SIZE;		
	} else {
		return audioBuffer + 2*lroundf(sound.getPosition()*sound.length);
	}
	
}

-(void) draw{
	//Segments
	ofSetColor(255, 255, 0);
	for(int i=0;i<NUMSEGMENTS-1;i++){
		float x=(float)i/NUMSEGMENTS;
		ofLine(x, segments[i].y, x+1.0/NUMSEGMENTS, segments[i+1].y);
	}
}


-(void) loadMic{
	int bufferSize = BUFFER_SIZE;
	liveAudio = true;
	audioRecorder = new DCAudioRecorder();
	audioRecorder->Configure(bufferSize);
	audioRecorder->Start();
	
	audioBuffer = (float*)calloc(bufferSize, sizeof(Float32));
	
	liveBuffer.mNumberBuffers = 1;
	liveBuffer.mBuffers[0].mNumberChannels = 2;
	liveBuffer.mBuffers[0].mData = audioBuffer;
	liveBuffer.mBuffers[0].mDataByteSize = bufferSize * sizeof(Float32);	
	
	
}

-(void) loadAudio:(NSString *)name{
	sound.loadSound([name cString]);
	sound.play();
	
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
