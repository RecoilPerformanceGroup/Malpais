//
//  Beach.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Beach.h"
#import "Keystoner.h"


@implementation Beach

-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"rollSmooth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"rollSpread"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"roll"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"alpha"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1000.0] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"floorDepth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-5.0 maxValue:5.0] named:@"drift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:5.0] named:@"offset"];
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named: 
		 [NSString stringWithFormat:@"wave%iOn",i]
		 ];
		[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUM_VOICES] named:
		 [NSString stringWithFormat:@"wave%iChannel",i]
		 ];
	}
	
	//	[self assignMidiChannel:9];
	
}

-(void) setup{
	
	waves = [NSMutableArray array];
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		waveForm[i] =  new MSA::Interpolator1D;
		waveForm[i]->reserve((int)roundf(PropF(@"resolution")));
		
		NSMutableArray * aVoice = [NSMutableArray arrayWithCapacity:MAX_RESOLUTION];
		
		for(int i=0;i<MAX_RESOLUTION;i++){
			[aVoice addObject:[NSNumber numberWithDouble:0.0]];
		}
		
		[waves addObject:aVoice];
	}
	
}


-(void) update:(NSDictionary *)drawingInformation{
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
		
		NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
		
		if (PropB(waveOnStr)) {
			
			NSString * waveChannelStr = [NSString stringWithFormat:@"wave%iChannel",iVoice];
			
			NSMutableArray * currentWave = [waves objectAtIndex:iVoice];
			
			NSMutableArray * newWave = [GetPlugin(Wave)
										getWaveFormWithIndex:(int)roundf(PropF(waveChannelStr))
										amplitude:1.0 
										driftSpeed:PropF(@"drift")
										smoothing:PropF(@"smoothing")
										freqeuncy:PropF(@"frequency")
										random:0
										offset: fmodf((ofGetElapsedTimef()*PropF(@"offset"))+(iVoice/(NUM_VOICES+1.0)), 1.0)
										withFormerArray:currentWave
										];
			
			[waves replaceObjectAtIndex:iVoice withObject:newWave];
			
			if ([newWave count] > 0) {
				waveForm[iVoice]->clear();
				for (int i=0; i < [newWave count]; i++) {
					waveForm[iVoice]->push_back([[newWave objectAtIndex:i] floatValue]);
				}
				
			}
			
		}	
		
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	
	ApplySurface(@"Floor");{
		
		ofSetColor(255, 255, 255, 255);
		ofFill();
		ofRect(0, -PropF(@"floorDepth"), [self aspect], 1+PropF(@"floorDepth"));

		ofSetColor(0, 0, 0, 255);
		
		glPushMatrix();{
			glTranslated(0, 0.5/(NUM_VOICES+1), 0);
			
			for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
				
				NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
				
				if (PropB(waveOnStr)) {
					float yPos = (1.0/(NUM_VOICES+1))*iVoice;
					ofxPoint2f * startP = new ofxPoint2f(0,yPos);
					ofxPoint2f * endP = new ofxPoint2f(1.0*[self aspect],yPos);
					[self drawWave:iVoice from:startP to:endP];
					delete startP;
					delete endP;
				}
			}
			
		} glPopMatrix();
		
		
		ofSetColor(0,0,0,255);
		ofFill();
		ofRect(-2.0, -PropF(@"floorDepth"), 4.0+[self aspect], -2.0); // top
		ofRect(-2.0, 1.0, 4.0+[self aspect], 2.0); // bottom
		ofRect(-2.0, -PropF(@"floorDepth"), 2.0, 4.0+PropF(@"floorDepth")); // left
		ofRect([self aspect], -PropF(@"floorDepth"), 4.0+[self aspect], 4.0+PropF(@"floorDepth")); // right
		
	} PopSurface();
	
}

-(void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end{
	
	ofxVec2f v1 = ofxVec2f(end->x, end->y)-ofxVec2f(begin->x, begin->y);
	ofxVec2f v2 = ofxVec2f(0,1.0);
	
	float length = v1.length();
	
	ofBeginShape();
	
	ofVertex(0, [self aspect]);
	ofVertex(0, 0);
	
	glPushMatrix();{
		
		ofFill();
		
//		glTranslated(begin->x,begin->y, 0);
//		glRotated(-v1.angle(v2)+90, 0, 0, 1);
		
		int resolution = PropI(@"resolution");
		float amplitude = PropF(@"amplitude");
		
		for (int i = 0;i< resolution; i++) {
			float x = 1.0/resolution*i;
			
			if (i < resolution) {
				ofxPoint2f p = ofxPoint2f(x*length, waveForm[iVoice]->sampleAt(x)*amplitude);
				ofVertex(p.x, p.y);
			}
			
		}
		
	} glPopMatrix();
	
	ofEndShape();

}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}



@end