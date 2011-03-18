//
//  Voice.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Voice.h"
#import "Keystoner.h"





@implementation Voice


-(float) falloff:(float)p{
	if(p >= 1)
		return 1;
	if(p<=0)
		return 0;
	p *= 6;
	p -= 3;
	
	return 1.0/(1.0+pow(5,-p));
}

-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"alpha"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:70.0 minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0.0 maxValue:1.0] named:@"smoothingRise"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothingFall"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.2 minValue:0.0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:0.05] named:@"lineWidth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-1.0 maxValue:1.0] named:@"preDrift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-1.0 maxValue:1.0] named:@"drift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"random"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUM_VOICES] named:@"waveChannel"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"falloff"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"falloffStrength"];

	
	[self assignMidiChannel:11];
}

-(void) setup{
	
	voice = nil;
	
	waveForms = [NSMutableArray arrayWithCapacity:NUM_BANDS];
	
	for(int iBand=0;iBand<NUM_BANDS;iBand++){
		
		WaveArray * aBand = [[WaveArray alloc]init];
		
		for (int iAmplitude=0; iAmplitude<MAX_RESOLUTION; iAmplitude++) {
			[aBand addFloat:0.0];
		}
		
		[waveForms addObject:aBand];
	}
	
	[waveForms retain];
}


-(void) update:(NSDictionary *)drawingInformation{
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	voice = [GetPlugin(Wave)getVoiceWithIndex:(int)roundf(PropF(@"waveChannel"))
									amplitude:1.0
									 preDrift:PropF(@"preDrift")
									postDrift:0
								smoothingRise:PropF(@"smoothingRise")
								smoothingFall:PropF(@"smoothingFall")
									smoothing:PropF(@"smoothing")
									freqeuncy:PropF(@"frequency")
								   resolution:PropF(@"resolution")
									   random:PropF(@"random")
									   offset:0
						 withFormerDictionary:[voice copy]
			 ];
	
	[voice retain];
	
	NSMutableArray * newWaveForms = [voice objectForKey:@"bandLines"];	
	int voiceLength = [[newWaveForms objectAtIndex:0] count];
	
	NSMutableArray * oldWaveForms = [NSMutableArray arrayWithArray:waveForms];	
	
	[waveForms removeAllObjects];
	
	float postDrift = PropF(@"drift");
	
	for(int iBand=0;iBand<NUM_BANDS;iBand++){
		
		WaveArray * aBand = [[WaveArray alloc]init];
		
		for (int iAmplitude=0; iAmplitude<voiceLength; iAmplitude++) {
			
			int iFrom = iAmplitude;
			if(postDrift != 0){
				iFrom += (postDrift>0)?-1:1;
				iFrom = (iFrom+voiceLength)%voiceLength;
			}
			
			double postDriftBalance = 1.0-powf((1.0-sqrt(fabs(postDrift))), 2.0);
			
			if([[newWaveForms objectAtIndex:iBand] count] == [[oldWaveForms objectAtIndex:iBand] count]){
				[aBand addFloat:
							  ((1.0-postDriftBalance)*[[newWaveForms objectAtIndex:iBand] getFloatAtIndex:iAmplitude])+
							  ((postDriftBalance)*[[oldWaveForms objectAtIndex:iBand] getFloatAtIndex:iFrom])
							  ];
			} else {
				[aBand addFloat:[[newWaveForms objectAtIndex:iBand] getFloatAtIndex:iAmplitude]];
			}

			
		}
		
		[waveForms addObject:aBand];
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	ofEnableAlphaBlending();
	
	float amplitude = PropF(@"amplitude");
	
	float lineWidth = PropF(@"lineWidth");
	
	ApplySurface(@"Wall");{
		
		ofSetColor(255, 255, 255, 255*PropF(@"alpha"));
		ofFill();
		
		glPushMatrix();{
			
			glTranslated(0, 0.5, 0);
			
			for (int iBand = 0;iBand<NUM_BANDS; iBand++) {
				
				int resolution = [[waveForms objectAtIndex:iBand] count];
				
				glBegin(GL_QUAD_STRIP);
				ofxPoint2f lastPoint = ofxPoint2f(0,0);
				for (int i = 0;i< resolution; i++) {
					
					float aspect = [self aspect];
					
					float x = ([self aspect]*i)/resolution;
					//					float f = [self falloff:(float)x/PropF(@"falloffStart")] * [self falloff:(1-x)/PropF(@"falloffEnd")];
					ofxPoint2f p = ofxPoint2f(x, [[waveForms objectAtIndex:iBand] getFloatAtIndex:i]*amplitude);
					p.y *= 1*(1-PropF(@"falloffStrength")) + PropF(@"falloffStrength")*[self falloff:x*1.0/PropF(@"falloff")]*[self falloff:([self aspect]-x)*1.0/PropF(@"falloff")];
					ofxVec2f v = p - lastPoint;
					ofxVec2f h = ofxVec2f(-v.y,v.x);
					h.normalize();
					h *= lineWidth;
					glVertex2f((p+h).x, (p+h).y);
					glVertex2f((p-h).x, (p-h).y);				
					lastPoint = p;
				}
				
				glEnd();
				
			}
			
		} glPopMatrix();
		
	} PopSurface();
	
}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Wall" viewNumber:0 projectorNumber:1] aspect] floatValue];
}



@end
