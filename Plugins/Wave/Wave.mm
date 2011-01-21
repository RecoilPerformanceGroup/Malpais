

#import "Wave.h"
#import "Keystoner.h"


@implementation Wave

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:100] named:@"numWaves"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:5.0] named:@"waveYScale"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0 maxValue:0.5] named:@"waveXScale"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1] named:@"waveXSpeed"];
	
	waves = [NSMutableArray array];
}

-(void) setup{
	
}

-(void) update:(NSDictionary *)drawingInformation{
	for(WaveObject * wave in waves){
		[wave updateWithSpeed:1.0/ofGetFrameRate() * PropF(@"waveXSpeed")];

	}
	
	if(PropI(@"numWaves") != [waves count]){
//		while(PropI(@"numWaves") > [waves count]){
			while(1 > [waves count]){

			WaveObject * obj = [[WaveObject alloc] init];
//			[obj loadAudio:@"/Users/jonas/Documents/udvilking/of_preRelease_v0062_osxSL_FAT/apps/examples/soundPlayerWaveformExample/bin/data/voice2.wav"];
				[obj loadAudio:[NSString stringWithFormat:@"/Users/jonas/Desktop/asdasd/STE-0%i.wav",[waves count]%10+33]];
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
	for(WaveObject * wave in waves){
		ofSetColor(50, 50, 50);
		glBegin(GL_LINE_STRIP);
		int numSamples = 5000*PropF(@"waveXScale");
		for(int i=0;i<numSamples;i++){
			float x = (float)i/(numSamples);
		//	int o = (i%2 == 0)?1:-1;
			glVertex2f(x, [wave y]+ PropF(@"waveYScale")*[wave getWaveData][i]/1.0); //(3.4*10e38)

		}
		glEnd();
		
		ofSetColor(50, 50, 255);

		glBegin(GL_LINE_STRIP);
		for(int i=0;i<[wave simplifiedCurve].size();i++){
			float x = (float)i/([wave simplifiedCurve].size());
			//	int o = (i%2 == 0)?1:-1;
		//	glVertex2f(x, [wave y]+ PropF(@"waveYScale")*[wave simplifiedCurve].at(i)/1.0); //(3.4*10e38)
			
		}
		glEnd();
		
		
		ofSetColor(255, 0, 0);
		ofLine(0, [wave y]+PropF(@"waveYScale")*[wave avgMin], 1, [wave y]+PropF(@"waveYScale")*[wave avgMin]);
		ofSetColor(0, 255, 0);
		ofLine(0, [wave y]+PropF(@"waveYScale")*[wave avgMax], 1, [wave y]+PropF(@"waveYScale")*[wave avgMax]);

	}
	PopSurface();
}

@end
