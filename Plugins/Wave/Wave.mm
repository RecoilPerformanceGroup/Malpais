//
//  Wave.mm
//  malpais
//
//  Created by ole kristensen on 11/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Wave.h"
#import "Keystoner.h"


@implementation Wave
static void BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel);


-(void) initPlugin{
	
	voiceWaveForms = [NSMutableArray arrayWithCapacity:NUM_VOICES];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"alpha wall"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"alpha floor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:10.0] named:@"line width"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"amplitude random"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"amplitude factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0 maxValue:10.0] named:@"frequency factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-10.0 maxValue:10.0] named:@"drift speed"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"smoothing factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:MAX_RESOLUTION minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10 minValue:1 maxValue:10] named:@"live voice samples"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10 minValue:1 maxValue:100] named:@"live voice amplification"];
	
	
	for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
		PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
		[self addProperty:p named:[NSString stringWithFormat:@"live voice band %i", iBand+1]];
	}
	NSMutableArray * aVoice = [NSMutableArray arrayWithCapacity:MAX_RESOLUTION];
	[voiceWaveForms addObject:aVoice];
	
	
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
			[self addProperty:p named:[NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1]];
		}
		NSMutableArray * aVoice = [NSMutableArray arrayWithCapacity:MAX_RESOLUTION];
		[voiceWaveForms addObject:aVoice];
	}
	
	//	mInputDeviceList = new AudioDeviceList(true);
	
	liveVoice = [[WaveObject alloc] init];
	[liveVoice loadMic];
	
	
}

-(void) setup{
	
	//	UInt32 propsize=0;
	//	propsize = sizeof(AudioDeviceID);
	//	verify_noerr (AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &propsize, &inputDevice));
	//	BuildDeviceMenu(mInputDeviceList, mInputDevices, inputDevice);
	
	
	// bind midi channels and controlnumbers
	
	int midiControlNumber;
	
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		midiControlNumber = iVoice*10;
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			PluginProperty * p = [properties objectForKey:[NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1]];
			[p setMidiChannel:[NSNumber numberWithInt:MIDI_CHANNEL]];
			if(midiControlNumber==0){
				[p setMidiNumber:[NSNumber numberWithInt:7]]; // undtagelse der bekræfter reglen
			} else {
				[p setMidiNumber:[NSNumber numberWithInt:midiControlNumber]];
			}
			midiControlNumber++;
		}
	}
	
}


-(void) update:(NSDictionary *)drawingInformation{
	
	
	liveSamples = 1 << (int)PropF(@"live voice samples");
	[liveVoice updateWithSpeed:1.0/ofGetFrameRate() * liveSamples];
	liveFFT.powerSpectrum(0, (int)liveSamples/2, [liveVoice getWaveData]-liveSamples, (int)liveSamples, &magnitude[0], &phase[0], &power[0], &avg_power);
	float amplification = PropF(@"live voice amplification");
	
	int thresholds[] = {0,4,6,10,16,24,150,liveSamples/2};
	
	for (int iBand=0; iBand < NUM_BANDS; iBand++) {
		float bandMagnitude= 0;
		for (int iMagnitude = thresholds[iBand]; iMagnitude < thresholds[iBand+1]; iMagnitude++) {
			bandMagnitude += magnitude[iMagnitude];
		}
		bandMagnitude *= 1.0/(thresholds[iBand+1]-thresholds[iBand]);
		NSString * propStr = [NSString stringWithFormat:@"live voice band %i", iBand+1];
		[[properties objectForKey:propStr] setFloatValue:(bandMagnitude/liveSamples)*amplification];
	}
	
	float resolution = round(PropF(@"resolution"));
	
	for(int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++){
		
		NSMutableArray * aVoice = [voiceWaveForms objectAtIndex:iVoice];
		
		if(resolution != [aVoice count]){
			
			[aVoice removeAllObjects];
			
			for(int i=0;i<resolution;i++){
				[aVoice addObject:[NSNumber numberWithDouble:0.0]];
			}
			
		}
		
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			
			NSString * propStr;
			
			if(iVoice == 0)
				propStr = [NSString stringWithFormat:@"live voice band %i", iBand+1];
			else 
				propStr = [NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1];
			
			float bandValue = PropF(propStr);
			
			//			double drift = PropF(@"drift speed")*ofGetElapsedTimef()*(2.0*((iBand-(NUM_BANDS/2))+1.0));
			double drift = PropF(@"drift speed")*ofGetElapsedTimef()*(iBand+1.0/NUM_BANDS);
			double smoothing = PropF(@"smoothing factor");
			double frequency = PropF(@"frequency factor");
			double ampRnd = ofRandom(0,PropF(@"amplitude random"));
			
			int voiceLength = [aVoice count]; 
			
			for (int i = 0; i < voiceLength; i++) {
				
				NSNumber * formerAmplitude;
				if (iBand == 0) {
					formerAmplitude = [NSNumber numberWithDouble:smoothing*[[aVoice objectAtIndex:i] doubleValue]];
				} else {
					formerAmplitude = [aVoice objectAtIndex:i];
				}
				
				NSNumber * anAmplitude = [NSNumber numberWithDouble:
										  ((1.0/NUM_BANDS) * sinf((((1.0*i*NUM_BANDS)/voiceLength)*(1.0+iBand))*frequency/*+(1.0/(1+iBand))*/-drift) * fmaxf(bandValue, ampRnd) * (1.0-smoothing))
										  +[formerAmplitude doubleValue]
										  ];
				
				[[voiceWaveForms objectAtIndex:iVoice] replaceObjectAtIndex:i withObject:anAmplitude];
				
			}
			
		}
		
		[voiceWaveForms replaceObjectAtIndex:iVoice withObject:aVoice];
		
	}
	
}


-(void) draw:(NSDictionary *)drawingInformation{
	
	float resolution = round(PropF(@"resolution"));
	
	ofSetColor(255, 255, 255);
	ofNoFill();
	ofSetLineWidth(PropF(@"line width"));
	
	ApplySurface(@"Floor"); {
		
		ofSetColor(255, 255, 255, 255.0*PropF(@"alpha floor"));
		
		NSMutableArray * aVoice;
		
		glTranslated(0, -0.5/NUM_VOICES+1, 0);
		
		
		for(aVoice in voiceWaveForms){
			
			glTranslated(0, 1.0/NUM_VOICES+1, 0);
			
			NSNumber * anAmplitude;
			
			glBegin(GL_LINE_STRIP);
			
			int i = 0;
			
			for(anAmplitude in aVoice){
				
				glVertex2d((Aspect(@"Floor",0)/resolution)*i, [anAmplitude doubleValue]*PropF(@"amplitude factor"));
				i++;
			} 
			
			glEnd();
			
		}
		
	} PopSurface();
	
	ApplySurface(@"Wall"); {
		
		ofSetColor(255, 255, 255, 255.0*PropF(@"alpha wall"));
		
		NSMutableArray * aVoice = [voiceWaveForms objectAtIndex:0];
		
		glTranslated(0, 0.5, 0);
		
		NSNumber * anAmplitude;
		
		glBegin(GL_LINE_STRIP);
		
		int i = 0;
		
		for(anAmplitude in aVoice){
			
			glVertex2d((Aspect(@"Wall",0)/resolution)*i, [anAmplitude doubleValue]*PropF(@"amplitude factor"));
			i++;
		} 
		
		glEnd();
		
		
	} PopSurface();
	
	
#pragma mark todo Live Voice
	
/*	// live audio on wall	

	ApplySurface(@"Wall"); {
		
		ofSetColor(0, 255, 210, 127);
		
		glTranslated(0, 0.5, 0);
		
		
		glBegin(GL_LINE_STRIP);
		
		for(int i=0;i<liveSamples;i++){
			float x = (Aspect(@"Wall",0)/liveSamples)*i;
			if(i < [liveVoice simplifiedCurve]->size())
				glVertex2f(x, PropF(@"amplitude factor")*[liveVoice simplifiedCurve]->at([liveVoice simplifiedCurve]->size()-i-1)/1.0); //(3.4*10e38)				
		}
		glEnd();
		
		
		ofSetColor(255, 0, 0, 127);
		
		for(int i=0;i<liveSamples;i++){
			float x = (Aspect(@"Wall",0)/liveSamples)*i*5;
			ofLine(x, 0.5, x, 0.5-(magnitude[i]*(1.0/liveSamples)));
		}
		
		
	} PopSurface();
*/	
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	
	ofFill();
	
	float levelsWidth = ofGetWidth() * 0.9;
	float levelsMargin = ofGetWidth() - levelsWidth;
	
	float bandHeight = ofGetHeight()*0.9/NUM_BANDS;
	
	for(int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++){
		glPushMatrix(); {
			glTranslated(iVoice*(levelsWidth*1.0/NUM_VOICES), 0, 0);
			ofSetColor(0, 0, 0);
			
			ofDrawBitmapString(ofToString(iVoice+1,0), ofPoint(0.0001,bandHeight*0.75));
			
			glPushMatrix(); {
				for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
					
					glTranslated(0,bandHeight, 0);
					
					NSString * propStr;
					
					if(iVoice == 0)
						propStr = [NSString stringWithFormat:@"live voice band %i", iBand+1];
					else 
						propStr = [NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1];
					
					
					//Full scales
					ofSetColor(24, 88, 120);
					ofRect(0, 0, 
						   (levelsWidth*0.75/NUM_VOICES+1),
						   (bandHeight*0.8)
						   );
					
					//Bars
					ofSetColor(68, 176, 240);
					ofRect(0, 0, 
						   (levelsWidth*0.75/NUM_VOICES+1)*PropF(propStr),
						   (bandHeight*0.8)
						   );
				}
				
			} glPopMatrix();
			
		} glPopMatrix();
		
	}
}


- (BOOL) autoresizeControlview{
	return YES;	
}

- (IBAction)inputDeviceSelected:(id)sender
{
	/**
	 int val = [mInputDevices indexOfSelectedItem];
	 AudioDeviceID newDevice =(mInputDeviceList->GetList())[val].mID;
	 
	 if(newDevice != inputDevice)
	 {		
	 //	[self stop:sender];
	 inputDevice = newDevice;
	 //[self resetPlayThrough];
	 }
	 **/
}

/*****
 static void BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel)
 {
 [menu removeAllItems];
 
 AudioDeviceList::DeviceList &thelist = devlist->GetList();
 int index = 0;
 for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
 while([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] != nil) {
 strcat((*i).mName, " ");
 }
 
 if([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] == nil) {
 [menu insertItemWithTitle: [NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding] atIndex:index];
 
 if (initSel == (*i).mID)
 [menu selectItemAtIndex: index];
 }
 }
 }
 **/

@end
