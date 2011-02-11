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


-(void) initPlugin{
	
	voiceWaveForms = [NSMutableArray arrayWithCapacity:NUM_VOICES];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:10.0] named:@"line width"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"amplitude factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"frequency factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0] named:@"smoothing factor"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:MAX_RESOLUTION minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			PluginProperty * p = [NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:1.0];
			[self addProperty:p named:[NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1]];
		}
		NSMutableArray * aVoice = [NSMutableArray arrayWithCapacity:MAX_RESOLUTION];
		[voiceWaveForms addObject:aVoice];
	}
	
}

-(void) setup{
	
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
	
	float resolution = round(PropF(@"resolution"));

	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		
#pragma todo SMOOTHING!
	
		NSMutableArray * aVoice = [voiceWaveForms objectAtIndex:iVoice];

		if(resolution != [aVoice count]){
			
			[aVoice removeAllObjects];
			
			for(int i=0;i<resolution;i++){
				[aVoice addObject:[NSNumber numberWithDouble:0.0]];
			}
			
		}
		
		for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
			
			NSString * propStr = [NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1];

			float bandValue = PropF(propStr);
						
			int voiceLength = [aVoice count]; 
			
			for (int i = 0; i < voiceLength; i++) {

				NSNumber * formerAmplitude;
				if (iBand == 0) {
					formerAmplitude = [NSNumber numberWithDouble:0.0];
				} else {
					formerAmplitude = [aVoice objectAtIndex:i];
				}
				
				NSNumber * anAmplitude = [NSNumber numberWithDouble:
				 ((1.0/NUM_BANDS) * sinf((((1.0*i*NUM_BANDS)/voiceLength)*(1.0+iBand))+(1.0/(1+iBand))) * bandValue)
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
		
		NSMutableArray * aVoice;

		glTranslated(0, -0.5/NUM_VOICES, 0);

		
		for(aVoice in voiceWaveForms){
			
			glTranslated(0, 1.0/NUM_VOICES, 0);

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
	
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	
	ofFill();
	
	float levelsWidth = ofGetWidth() * 0.9;
	float levelsMargin = ofGetWidth() - levelsWidth;
	
	float bandHeight = ofGetHeight()*0.9/NUM_BANDS;
	
	for(int iVoice = 0; iVoice < NUM_VOICES; iVoice++){
		glPushMatrix(); {
			glTranslated(iVoice*(levelsWidth*1.0/NUM_VOICES), 0, 0);
			ofSetColor(0, 0, 0);
			
			ofDrawBitmapString(ofToString(iVoice+1,0), ofPoint(0.0001,bandHeight*0.75));
			
			glPushMatrix(); {
				for (int iBand = 0; iBand < NUM_BANDS; iBand++) {
					
					glTranslated(0,bandHeight, 0);
					
					NSString * propStr = [NSString stringWithFormat:@"voice %i band %i", iVoice+1, iBand+1];
					
					//Full scales
					ofSetColor(24, 88, 120);
					ofRect(0, 0, 
						   (levelsWidth*0.75/NUM_VOICES),
						   (bandHeight*0.8)
						   );
					
					//Bars
					ofSetColor(68, 176, 240);
					ofRect(0, 0, 
						   (levelsWidth*0.75/NUM_VOICES)*PropF(propStr),
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


@end
