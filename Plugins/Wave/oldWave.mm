/**


#import "Wave.h"
#import "Keystoner.h"


@implementation Wave

-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"mode"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:100] named:@"numWaves"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:5.0] named:@"waveYScale"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0 maxValue:0.5] named:@"waveXScale"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1] named:@"waveXSpeed"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:2000 minValue:0 maxValue:2000] named:@"waveSpeed"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:20] named:@"waveDuplicates"];

	waves = [NSMutableArray array];
//	mInputDeviceList = new AudioDeviceList(true);
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	//	NSLog(@"Object %@",object);
	if(object == Prop(@"mode")){
		//		NSLog(@"Mode change");
		[waves removeAllObjects];
	}
}

-(void) setup{
//	UInt32 propsize=0;
//	
//	propsize = sizeof(AudioDeviceID);
//	verify_noerr (AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &propsize, &inputDevice));
//	
//	BuildDeviceMenu(mInputDeviceList, mInputDevices, inputDevice);
}

-(void) update:(NSDictionary *)drawingInformation{
//	if([waves count] > 0){
//	 WaveObject * wave = [waves objectAtIndex:0];
//	 for(int i=0;i<NUMSEGMENTS;i++){
//	 [wave segments][i].y = sin(ofGetElapsedTimeMillis()/PropF(@"waveSpeed"))/5.0;
//	 }
//	 }
	
	//Call update on all waves
	int waveNo = 0;
	for(WaveObject * wave in waves){
		[wave updateWithSpeed:1.0/ofGetFrameRate() * PropF(@"waveXSpeed")];
	}
	
	//Generate new waves or delete 
	if(PropI(@"numWaves") != [waves count]){
		while(PropI(@"numWaves") > [waves count]){
			WaveObject * obj = [[WaveObject alloc] init];
			if(PropI(@"mode") == 1){
				//			[obj loadAudio:@"/Users/jonas/Documents/udvilking/of_preRelease_v0062_osxSL_FAT/apps/examples/soundPlayerWaveformExample/bin/data/voice2.wav"];
				
				[obj loadAudio:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/Desktop/asdasd/STE-00%i.wav",[waves count]%10+1]]];
			} else if(PropI(@"mode") == 0){
				[obj loadMic];
			}
			[obj setWaves:waves];
			[waves addObject:obj];
		}
		while(PropI(@"numWaves") < [waves count]){
			[waves removeLastObject];
		}		
	}
}

-(void) draw:(NSDictionary *)drawingInformation{
	ApplySurface(@"Floor");
	ofSetColor(255, 255, 255);
	ofEnableAlphaBlending();
	for(WaveObject * wave in waves){
		//[wave draw];
		glTranslated(0, 1.0/[waves count], 0);
		ofSetColor(190,190,190,150);
		
		int numSamples = 10000*PropF(@"waveXScale");
		for(int j=0;j<PropI(@"waveDuplicates");j++){
			//			if(0 - j*numSamples > 0){
			//glTranslated(0, 0.1, 0); 
			glBegin(GL_LINE_STRIP);
			
			for(int i=0;i<numSamples;i+=2){
				float x = (float)i/(numSamples);
				//	int o = (i%2 == 0)?1:-1;
				glVertex2f(x*Aspect(@"Floor",0), 0.0+PropF(@"waveYScale")*[wave getWaveData][-(i+j*(numSamples-2))]); //(3.4*10e38)				
			}
//			for(int i=0;i<numSamples;i++){
//				float x = (float)i/(numSamples);
//				//	int o = (i%2 == 0)?1:-1;
//				if(i < [wave simplifiedCurve]->size())
//					glVertex2f(x, 0.5+PropF(@"waveYScale")*[wave simplifiedCurve]->at([wave simplifiedCurve]->size()-i-1)/1.0); //(3.4*10e38)				
//			}
		glEnd();
			//			}
		}
		
		ofSetColor(50, 50, 255);
		
//			glBegin(GL_LINE_STRIP);
//		 for(int i=0;i<[wave simplifiedCurve].size();i++){
//		 float x = (float)i/([wave simplifiedCurve].size());
//		 //	int o = (i%2 == 0)?1:-1;
//		 //	glVertex2f(x, [wave y]+ PropF(@"waveYScale")*[wave simplifiedCurve].at(i)/1.0); //(3.4*10e38)
//		 
//		 }
//		 glEnd();
//		 
//		 
//		 ofSetColor(255, 0, 0);
//		 ofLine(0, [wave y]+PropF(@"waveYScale")*[wave avgMin], 1, [wave y]+PropF(@"waveYScale")*[wave avgMin]);
//		 ofSetColor(0, 255, 0);
//		 ofLine(0, [wave y]+PropF(@"waveYScale")*[wave avgMax], 1, [wave y]+PropF(@"waveYScale")*[wave avgMax]);
//		 
	}
	PopSurface();
}

-(IBAction) startWave:(id)sender{
	WaveObject * bestWave = nil;
	for(WaveObject * wave in waves){
		if(bestWave == nil || [bestWave segments][0].y > [wave segments][0].y)
			bestWave = wave;
	}
	
	if(bestWave != nil){
		for(int i=0;i<NUMSEGMENTS;i++){
			[bestWave segments][i].v = 1;
		}
	}
	
}

- (IBAction)inputDeviceSelected:(id)sender
{
	int val = [mInputDevices indexOfSelectedItem];
	AudioDeviceID newDevice =(mInputDeviceList->GetList())[val].mID;
	
	if(newDevice != inputDevice)
	{		
		//	[self stop:sender];
		inputDevice = newDevice;
		//[self resetPlayThrough];
	}
}


@end
**/