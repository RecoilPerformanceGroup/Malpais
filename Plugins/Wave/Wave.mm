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
	
	voices = [NSMutableArray arrayWithCapacity:NUM_VOICES+1];
	
	[voices retain];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"random"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-2.0 maxValue:2.0] named:@"preDrift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1.0 maxValue:1.0] named:@"postDrift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"smoothingRise"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"smoothingFall"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:70.0 minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10 minValue:1 maxValue:10] named:@"liveVoiceSamples"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:90 minValue:1 maxValue:100] named:@"liveVoiceAmplification"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"recordLive"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"updateWaveForms"];
	
	//make properties for live voice
	for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
		PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
		[self addProperty:p named:[NSString stringWithFormat:@"liveVoiceBand%i", iBand+1]];
	}
	
	PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
	[self addProperty:p named:@"liveVoiceOffset"];
	
	[voices addObject:[NSNull null]];
	
	
	//make properties for rest of voices
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		
		[voices addObject:[NSNull null]];
		
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
			[self addProperty:p named:[NSString stringWithFormat:@"voice%iBand%i", iVoice+1, iBand+1]];
		}
		PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
		[self addProperty:p named:[NSString stringWithFormat:@"voice%iOffset", iVoice+1]];
	}
	
	mInputDeviceList = new AudioDeviceList(true);
	
	liveVoice = [[WaveObject alloc] init];
	[liveVoice loadMic];
	
	[self assignMidiChannel:1];
	
}

-(void) setup{
	
	UInt32 propsize=0;
	propsize = sizeof(AudioDeviceID);
	verify_noerr (AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &propsize, &inputDevice));
	BuildDeviceMenu(mInputDeviceList, mInputDevices, inputDevice);
	[mInputDevices setEnabled:NO];
	
	// bind midi channels and controlnumbers
	
	int midiControlNumber;
	
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		midiControlNumber = iVoice*10;
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			PluginProperty * p = [properties objectForKey:[NSString stringWithFormat:@"voice%iBand%i", iVoice+1, iBand+1]];
			if(midiControlNumber==0){
				[p setManualMidiNumber:[NSNumber numberWithInt:7]]; // undtagelse der bekræfter reglen, da nummer 0 ikke kan bruges
			} else {
				[p setManualMidiNumber:[NSNumber numberWithInt:midiControlNumber]];
			}
			midiControlNumber++;
		}
	}
	
	[self updateAllVoices];
}

-(void) updateAllVoices{
	
	NSMutableArray *newVoices = [NSMutableArray arrayWithCapacity:NUM_VOICES+1];
	
	for (int iVoice = 0; iVoice < NUM_VOICES+1;iVoice++) {
		
		NSString * propStr;
		
		if(iVoice == 0)
			propStr = [NSString stringWithFormat:@"liveVoiceOffset"];
		else 
			propStr = [NSString stringWithFormat:@"voice%iOffset", iVoice];
		
		[newVoices addObject:
		 [self getVoiceWithIndex:iVoice 
					   amplitude:PropF(@"amplitude") 
						preDrift:PropF(@"preDrift")
					   postDrift:PropF(@"postDrift")
				   smoothingRise:PropF(@"smoothingRise")
				   smoothingFall:PropF(@"smoothingFall")
					   smoothing:PropF(@"smoothing")
					   freqeuncy:PropF(@"frequency")
					  resolution:PropF(@"resolution")
						  random:PropF(@"random")
						  offset:PropF(propStr)
			withFormerDictionary:[voices objectAtIndex:iVoice]]
		 ];
		
	}
	
	voices = [newVoices retain];
	
}


-(void) update:(NSDictionary *)drawingInformation{
	
	float now = ofGetElapsedTimef();
	frameRateDeltaTime = now - lastUpdateTime;
	lastUpdateTime = now;
	
	if (PropB(@"recordLive")) {
		liveSamples = 1 << (int)PropF(@"liveVoiceSamples");
		[liveVoice updateWithSpeed:1.0/ofGetFrameRate() * liveSamples];
		liveFFT.powerSpectrum(0, (int)liveSamples/2, [liveVoice getWaveData]-liveSamples, (int)liveSamples, &magnitude[0], &phase[0], &power[0], &avg_power);
		float amplification = PropF(@"liveVoiceAmplification");
		
		int thresholds[] = {0,6,7,8,10,15,60,liveSamples/4};
		
		for (int iBand=0; iBand < NUM_BANDS; iBand++) {
			float bandMagnitude= 0;
			for (int iMagnitude = thresholds[iBand]; iMagnitude < thresholds[iBand+1]; iMagnitude++) {
				bandMagnitude += magnitude[iMagnitude];
			}
			bandMagnitude *= 1.0/(thresholds[iBand+1]-thresholds[iBand]);
			NSString * propStr = [NSString stringWithFormat:@"liveVoiceBand%i", iBand+1];
			
			// linear amplification
			bandMagnitude = (bandMagnitude/liveSamples)*amplification;
			
			// 'logaritmisk' transmogrif
			bandMagnitude = fmin(bandMagnitude, 1.0); // the formula below goes 0 at values > 1.0
			bandMagnitude = 1.0-powf((1.0-sqrt(bandMagnitude)), 1.1);;
			
			[[properties objectForKey:propStr] setFloatValue:bandMagnitude];
		}
	}
	
	if(PropB(@"updateWaveForms")){
		[self updateAllVoices];
	}
	
}


-(void) draw:(NSDictionary *)drawingInformation{
	
	/**
	 float resolution = roundf(PropF(@"resolution"));
	 
	 ofSetColor(255, 255, 255);
	 ofNoFill();
	 ofSetLineWidth(PropF(@"lineWidth"));
	 
	 ApplySurface(@"Floor"); {
	 
	 if (PropF(@"alphaFloor") > 0) {
	 
	 ofSetColor(255, 255, 255, 255.0*PropF(@"alphaFloor"));
	 
	 NSMutableArray * aVoice;
	 
	 glTranslated(0, -0.5/NUM_VOICES+1, 0);
	 
	 
	 for(aVoice in voiceWaveForms){
	 
	 glTranslated(0, 1.0/NUM_VOICES+1, 0);
	 
	 NSNumber * anAmplitude;
	 
	 glBegin(GL_LINE_STRIP);
	 
	 int i = 0;
	 
	 for(anAmplitude in aVoice){
	 
	 glVertex2d((Aspect(@"Floor",0)/resolution)*i, [anAmplitude doubleValue]*PropF(@"amplitude"));
	 i++;
	 } 
	 
	 glEnd();
	 
	 }
	 }
	 
	 } PopSurface();
	 
	 ApplySurface(@"Wall"); {
	 
	 if (PropF(@"alphaWall") > 0) {
	 
	 ofSetColor(255, 255, 255, 255.0*PropF(@"alphaWall"));
	 
	 NSMutableArray * aVoice = [voiceWaveForms objectAtIndex:0];
	 
	 glTranslated(0, 0.5, 0);
	 
	 NSNumber * anAmplitude;
	 
	 glBegin(GL_LINE_STRIP);
	 
	 int i = 0;
	 
	 for(anAmplitude in aVoice){
	 
	 glVertex2d((Aspect(@"Wall",0)/resolution)*i, [anAmplitude doubleValue]*PropF(@"amplitude"));
	 i++;
	 } 
	 
	 glEnd();
	 
	 }
	 
	 } PopSurface();
	 **/
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	
	ofEnableAlphaBlending();
	
	ofFill();
	
	float levelsWidth = ofGetWidth() * 0.9;
	float levelsMargin = ofGetWidth() - levelsWidth;
	
	float bandHeight = ofGetHeight()*0.9/NUM_BANDS;
	
	for(int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++){
		
		WaveArray * aVoice = [[voices objectAtIndex:iVoice] objectForKey:@"waveLine"];
		float resolution = [aVoice count];
		
		glPushMatrix(); {
			glTranslated(iVoice*(levelsWidth*1.0/NUM_VOICES), 0, 0);
			ofSetColor(0, 0, 0);
			ofFill();
			
			//			ofDrawBitmapString(ofToString(iVoice+1,0), ofPoint(0.0001,bandHeight*0.75));
			
			glPushMatrix(); {
				
				for (int iBand = NUM_BANDS-1; iBand >= 0; iBand--) {
					
					NSString * propStr;
					
					if(iVoice == 0)
						propStr = [NSString stringWithFormat:@"liveVoiceBand%i", iBand+1];
					else 
						propStr = [NSString stringWithFormat:@"voice%iBand%i", iVoice, iBand+1];
					
					//Full scales
					if (iVoice == 0) {
						ofSetColor(24, 120, 88);
					} else {
						ofSetColor(24, 88, 120);
					}
					ofFill();
					ofRect(0, 0, 
						   (levelsWidth/(NUM_VOICES+1.0)),
						   (bandHeight*0.4)
						   );
					
					ofSetColor(0, 0, 0,127);
					ofSetLineWidth(1.5);
					ofNoFill();
					ofRect(0, 0, 
						   (levelsWidth/(NUM_VOICES+1.0)),
						   (bandHeight*0.4)
						   );
					
					
					//Bars
					if (iVoice == 0) {
						ofSetColor(68, 240, 176);
					} else {
						ofSetColor(68, 176, 240);
					}
					ofFill();
					ofRect(0, 0, 
						   (levelsWidth/(NUM_VOICES+1.0))*PropF(propStr),
						   (bandHeight*0.4)
						   );
					
					// sines
					
					ofNoFill();
					ofSetLineWidth(1.5);
					ofSetColor(255, 255, 63, 63);
					
					glBegin(GL_LINE_STRIP);
					
					for(int a = 0; a < resolution; a++){
						
						float aBandAmplitude = [[[[voices objectAtIndex:iVoice] objectForKey:@"bandLines"] objectAtIndex:iBand] getFloatAtIndex:a] ;
						
						
						glVertex2d(((levelsWidth/(NUM_VOICES+1.0))/(resolution-1))*a, (bandHeight*0.4*0.5)+(aBandAmplitude*bandHeight*0.2));
					} 
					
					glEnd();
					
					// smoothed level
					
					ofSetColor(255, 255, 255, 127);
					ofSetLineWidth(1.5);
					ofNoFill();
					float smoothLevel = [[[[voices objectAtIndex:iVoice] objectForKey:@"bandLevels"] objectAtIndex:iBand] floatValue];
					ofLine((levelsWidth/(NUM_VOICES+1.0))*smoothLevel, 0, 
						   (levelsWidth/(NUM_VOICES+1.0))*smoothLevel, bandHeight*0.4);
					
					ofSetColor(0, 0, 0,127);
					ofSetLineWidth(1.5);
					ofNoFill();
					ofRect(0, 0, 
						   (levelsWidth/(NUM_VOICES+1.0))*PropF(propStr),
						   (bandHeight*0.4)
						   );
					
					glTranslated(0,bandHeight*0.5, 0);
					
				}
				
				glTranslated(0,bandHeight*0.25, 0);
				
				if (PropB(@"updateWaveForms")) {
					ofSetColor(0, 0, 0, 127);
				} else {
					ofSetColor(0, 0, 0, 31);
				}
				
				ofFill();
				ofRect(0, 0, (levelsWidth/(NUM_VOICES+1.0)), bandHeight*1.5);
				
				ofSetColor(0, 0, 0,127);
				ofSetLineWidth(1.5);
				ofNoFill();
				ofRect(0, 0, (levelsWidth/(NUM_VOICES+1.0)), bandHeight*1.5);
				
				ofNoFill();
				ofSetLineWidth(1.5);
				ofSetColor(255, 255, 0);
				
				glBegin(GL_LINE_STRIP);
				
				int i = 0;
				
				for(int iAmplitude = 0; iAmplitude < [aVoice count];iAmplitude++){
					
					glVertex2d(((levelsWidth/(NUM_VOICES+1.0))/(resolution-1))*i, (bandHeight*1.5*0.5)+([aVoice getFloatAtIndex:iAmplitude]*bandHeight*1.5*0.5));
					i++;
				} 
				
				glEnd();
				
				
			} glPopMatrix();
			
			
		} glPopMatrix();
		
	}
	
	glPushMatrix();{
		glTranslated(0, ofGetHeight(), 0);
		if (PropB(@"recordLive")) {
			ofSetColor(0, 0, 0, 127);
		} else {
			ofSetColor(0, 0, 0, 31);
		}
		ofFill();
		ofRect(0, 0, ofGetWidth(), -bandHeight*2.0);
		ofNoFill();
		ofSetLineWidth(2.0);
		
		//magnitude
		ofSetColor(0,0, 255, 255.0);
		for(int i=0;i<liveSamples/2;i++){
			float x = ((ofGetWidth()*1.0)/liveSamples)*i*2.0;
			ofLine(x, 0, x, -bandHeight*(magnitude[i]*(10.0/liveSamples)));
		}
		//power
		ofSetColor(255,0,0, 255.0*0.5);
		for(int i=0;i<liveSamples/2;i++){
			float x = ((ofGetWidth()*1.0)/liveSamples)*i*2.0;
			ofLine(x, 0, x, -bandHeight*(power[i]*(10.0/liveSamples)));
		}
		
		ofSetColor(0, 0, 0,127);
		ofSetLineWidth(1.5);
		ofNoFill();
		ofRect(0, 0, ofGetWidth(), -bandHeight*2.0);
		
		if (PropB(@"recordLive")) {
			ofSetLineWidth(2.0);
			
			glTranslated(0, -bandHeight, 0);
			ofSetColor(0,0,0, 255.0*0.5);
			
			glBegin(GL_LINE_STRIP);
			for(int i=0;i<[liveVoice simplifiedCurve]->size();i++){
				float x = ((ofGetWidth()*1.0)/[liveVoice simplifiedCurve]->size())*i;
				glVertex2f(x, [liveVoice simplifiedCurve]->at([liveVoice simplifiedCurve]->size()-i-1)*bandHeight);	
			}
			glEnd();
		}   
		
	}glPopMatrix();
	
}

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
			   withFormerDictionary:(NSDictionary*)formerDictionary
{
	
	NSMutableDictionary * newVoice = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:index],@"index", 
									  [NSNumber numberWithFloat:amplitude],@"amplitude", 
									  [NSNumber numberWithFloat:preDrift],@"preDrift",
									  [NSNumber numberWithFloat:postDrift],@"postDrift",
									  [NSNumber numberWithFloat:smoothingRise],@"smoothingRise",
									  [NSNumber numberWithFloat:smoothingFall],@"smoothingFall",
									  [NSNumber numberWithFloat:smoothing],@"smoothing",
									  [NSNumber numberWithFloat:frequency],@"frequency",
									  [NSNumber numberWithInt:resolution],@"resolution",
									  [NSNumber numberWithFloat:randomFactor],@"randomFactor",
									  [NSNumber numberWithFloat:offset],@"offset",
									  [NSMutableArray arrayWithCapacity:NUM_BANDS], @"bandLevels",
									  [NSMutableArray arrayWithCapacity:NUM_BANDS], @"bandLines",
									  [[WaveArray alloc] init], @"waveLine",
									  nil];
	
	if (NUM_VOICES+1>index) {
		
		NSMutableArray * oldBandLevels = [NSMutableArray arrayWithCapacity:NUM_BANDS];
		
		NSMutableArray * oldBandLines = [NSMutableArray arrayWithCapacity:NUM_BANDS];
		NSMutableArray * newBandLines = [NSMutableArray arrayWithCapacity:NUM_BANDS];
		
		WaveArray * oldWaveLine = [[WaveArray alloc] init];
		WaveArray * newWaveLine = [[WaveArray alloc] init];
		
		
		if (formerDictionary != nil && ![[NSNull null] isEqualTo:formerDictionary] ) {
			
			// we have former values - now to be read without offset
			
			int iFrom;
			int formerResolution = [[formerDictionary objectForKey:@"resolution"] intValue];
			float formerOffset = [[formerDictionary objectForKey:@"offset"] floatValue];
			int formerOffsetIndex = roundf(formerResolution * formerOffset);
			
			// de-offset oldWaveLine
			iFrom = (formerResolution-formerOffsetIndex)%formerResolution;
			
			WaveArray * formerWaveLine = [formerDictionary objectForKey:@"waveLine"];
			
			for (int iTo = 0; iTo < formerResolution; iTo++) {
				[oldWaveLine addFloat:[formerWaveLine getFloatAtIndex:iFrom]];
				iFrom = (iFrom+1)%formerResolution;
			}
			if(formerResolution < resolution){ // handle increasing resolution by padding zeros 
				for(int i=0; i < resolution - formerResolution; i++){
					[oldWaveLine addFloat:0.0];
				}
			}
			
			// de-offset oldBandLines
			for(int iBand = 0; iBand < NUM_BANDS; iBand++){
				
				WaveArray * formerBandLine = [[formerDictionary objectForKey:@"bandLines"] objectAtIndex:iBand];
				WaveArray * oldBandLine = [[WaveArray alloc] init];
				
				iFrom = (formerResolution-formerOffsetIndex)%formerResolution;
				for (int iTo = 0; iTo < formerResolution; iTo++) {
					[oldBandLine addFloat:[formerBandLine getFloatAtIndex:iFrom]];
					iFrom = (iFrom+1)%formerResolution;
				}
				if(formerResolution < resolution){ // handle increasing resolution by padding zeros 
					for(int i=0; i < resolution - formerResolution; i++){
						[oldBandLine addFloat:0.0];
					}
				}
				[oldBandLines addObject:oldBandLine];
			}
			
			// fill oldBandLeves
			
			oldBandLevels = [formerDictionary objectForKey:@"bandLevels"];
			
		} else {
			// we don't have former values - so we make a zero'ed history
			
			//create empty oldWaveLine
			for (int i = 0; i < resolution; i++) {
				[oldWaveLine addFloat:0.0];
			}
			//create empty oldBandLines				
			for(int iBand = 0; iBand < NUM_BANDS; iBand++){
				WaveArray * oldBandLine = [[WaveArray alloc]init];
				for (int i = 0; i < resolution; i++) {
					[oldBandLine addFloat:0.0];
				}
				[oldBandLines addObject:oldBandLine];
				[oldBandLevels addObject:[NSNumber numberWithFloat:0.0]];
			}
		}
		
		double smoothingFactor = 1.0-powf((1.0-sqrt(smoothing)), 2.5);
		double smoothingRiseFactor = 1.0-powf((1.0-sqrt(smoothingRise)), 2.5);
		double smoothingFallFactor = 1.0-powf((1.0-sqrt(smoothingFall)), 2.5);
		
		float now = ofGetElapsedTimef();
		
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {

			double ampRnd = ofRandom(0,randomFactor);

			double drift = preDrift*ofGetElapsedTimef()*(iBand+1.0/NUM_BANDS)*2.0*PI;
			
			// set the band level smoothed
			NSString * propStr;
			if(index == 0)
				propStr = [NSString stringWithFormat:@"liveVoiceBand%i", iBand+1];
			else 
				propStr = [NSString stringWithFormat:@"voice%iBand%i", index, iBand+1];
			float oldBandLevel = [[oldBandLevels objectAtIndex:iBand] floatValue];
			float newBandLevel = PropF(propStr);
			newBandLevel = fmaxf(newBandLevel, ampRnd);
			if (newBandLevel > oldBandLevel) {
				newBandLevel = (smoothingRiseFactor*oldBandLevel)+((1.0-smoothingRiseFactor)*newBandLevel);
			} else {
				newBandLevel = (smoothingFallFactor*oldBandLevel)+((1.0-smoothingFallFactor)*newBandLevel);
			}
			
			[[newVoice objectForKey:@"bandLevels"] addObject:[NSNumber numberWithFloat:newBandLevel]];
			
			WaveArray * newBandLine = [[WaveArray alloc]init];
			
			for (int i = 0; i < resolution; i++) {
				
				float formerAmplitude;
				
				if (iBand == 0) {
					//when doing first band we take the former value
					formerAmplitude = smoothingFactor*[oldWaveLine getFloatAtIndex:i];
					//formerAmplitude = 0;
				} else {
					//when doing other bands we take our own value, which is why we scale by 1.0/NUM_BANDS when adding the bands up
					formerAmplitude = [newWaveLine getFloatAtIndex:i];
				}
				
				float amp = sinf((((1.0*i)/resolution)*(1.0+iBand))*frequency*PI*2.0/*+(1.0/(1+iBand))*/-drift) * newBandLevel * amplitude;
								
				float anAmplitude = ((1.0/NUM_BANDS) * amp			// scaling with 1.0/NUM_BANDS so the sum of bands will be normalised
										   * (1.0-smoothingFactor)
										   )+formerAmplitude					// when adding the formerAmplitude, that we got from the if clause above
				;
								
				if (iBand == 0) {
					[newWaveLine addFloat:anAmplitude];
				} else {
					[newWaveLine setFloat:anAmplitude atIndex:i];
				}
				
				[newBandLine addFloat:amp];
				
			}
			[newBandLines addObject:newBandLine];
			
		}
		
		/*//post drift
		 for (int i = 0; i < resolution; i++) {
		 
		 int iFrom = i;
		 if(postDrift != 0){
		 iFrom += (postDrift<0)?-1:1;
		 iFrom = (iFrom+resolution)%resolution;
		 }
		 float postDriftBalance = fabs(postDrift);
		 [newWaveLine replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:
		 ((1.0-postDriftBalance)*[[newWaveLine objectAtIndex:i] floatValue])+
		 ((postDriftBalance)*[[oldWaveLine objectAtIndex:iFrom] floatValue])
		 ]];
		 
		 }
		 */
		
		int iFrom;
		int offsetIndex = roundf(resolution * offset);
		
		// offset newWaveLine
		iFrom = offsetIndex%resolution;
		for (int iTo = 0; iTo < resolution; iTo++) {
			[[newVoice objectForKey:@"waveLine"] addFloat:[newWaveLine getFloatAtIndex:iFrom]];
			iFrom = (iFrom+1)%resolution;
		}
		
		// offset newBandLines
		for(int iBand = 0; iBand < NUM_BANDS; iBand++){
			
			WaveArray * newBandLineWithOffset = [[WaveArray alloc]init];
			iFrom = offsetIndex%resolution;
			
			for (int iTo = 0; iTo < resolution; iTo++) {
				[newBandLineWithOffset addFloat:[[newBandLines objectAtIndex:iBand] getFloatAtIndex:iFrom]];
				iFrom = (iFrom+1)%resolution;
			}
			[[newVoice objectForKey:@"bandLines"] addObject:newBandLineWithOffset];
		}
		
		[newVoice retain];
		
		[voices replaceObjectAtIndex:index withObject:newVoice];
		
		return newVoice;
		
	} else {
		return nil;
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

@end

@implementation WaveArray

-(id)init {
	self = [super init];
	if (self) {
		count = 0;
	}
	return self;
}

-(void) addFloat:(float)floatValue{

	if (floatValue > 2.0) {
		Debugger();
	}
	
	if ([self count] < MAX_RESOLUTION) {
		array[count++] = floatValue;
	}	
}

-(float) getFloatAtIndex:(int)index{
	if (index < count) {

		if (array[index] > 2.0) {
			Debugger();
		}
		return array[index];
	}
}

-(void) setFloat:(float)floatValue atIndex:(int)index{
	if (index < count) {
		array[index] = floatValue;
	}
}

-(void) clear{
	count = 0;
}

-(int) count{
	return count;
}

@end

	