//
//  Beach.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Beach.h"
#import "Keystoner.h"
#import "SceneX.h"

@implementation Beach

-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"rollSmooth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"spread"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:1.0 maxValue:4.0] named:@"backlineNo"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"rollPos"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:70.0 minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"alpha"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0.0 maxValue:1.0] named:@"smootingRise"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.35 minValue:0.0 maxValue:1.0] named:@"smoothingFall"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothing"];
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
	
	[self assignMidiChannel:12];
	
}

-(void) setup{
	
	gradient.loadImage([[[NSBundle mainBundle] pathForResource:@"gradient wave" ofType:@"png" inDirectory:@""] cString]);
	
	voices = [NSMutableArray array];
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		waveForm[i] = new MSA::Interpolator1D;
		waveForm[i]->reserve((int)roundf(PropF(@"resolution")));
		
		[voices addObject:[NSNull null]];
		waveFormYpos[i] = PropF(@"rollPos");
	}
	
}


-(void) update:(NSDictionary *)drawingInformation{
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	float rollPos = PropF(@"rollPos");
	
	rollPosHistory.push_back(rollPos);
	
	if (rollPosHistory.size() > ROLL_POS_HISTORY_LENGTH) {
		rollPosHistory.erase(rollPosHistory.begin());
	}
	
	for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
		
		NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
		
		if (PropB(waveOnStr)) {
			
			NSString * waveChannelStr = [NSString stringWithFormat:@"wave%iChannel",iVoice];
			
			NSDictionary * currentVoice = [voices objectAtIndex:iVoice];
			
			NSDictionary * newVoice = [GetPlugin(Wave)getVoiceWithIndex:(int)roundf(PropF(waveChannelStr))
															  amplitude:1.0
															   preDrift:PropF(@"drift")
															  postDrift:0
														  smoothingRise:PropF(@"smoothingRise")
														  smoothingFall:PropF(@"smoothingFall")
															  smoothing:PropF(@"smoothing")
															  freqeuncy:PropF(@"frequency")
															 resolution:PropF(@"resolution")
																 random:0
																 offset:fmodf((ofGetElapsedTimef()*PropF(@"offset"))+(iVoice/(NUM_VOICES+1.0)), 1.0)
												   withFormerDictionary:currentVoice
									   ];
			
			[voices replaceObjectAtIndex:iVoice withObject:newVoice];
			
			WaveArray * newWave = [newVoice objectForKey:@"waveLine"];
			
			if ([newWave count] > 0) {
				waveForm[iVoice]->clear();
				for (int i=0; i < [newWave count]; i++) {
					waveForm[iVoice]->push_back([newWave getFloatAtIndex:i]);
				}
				
			}
			
		}	
		
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	float spread = PropF(@"spread");
	double rollPosSmoothing = 1.0-powf((1.0-sqrt(PropF(@"rollSmooth"))), 2.5);
	
	ofEnableAlphaBlending();
	
	ApplySurface(@"Floor");{
		
		ofSetColor(255, 255, 255, 255*PropF(@"alpha"));
		ofFill();
		glBlendFunc(GL_SRC_ALPHA, GL_ONE);

		glPushMatrix();{
			
			for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
				
				int myHistoryIndex = ROLL_POS_HISTORY_LENGTH-(int)roundf(spread*(ROLL_POS_HISTORY_LENGTH/(NUM_VOICES+1.0))*(iVoice+1));
				
				float newYpos;
				
				if (rollPosHistory.size() > myHistoryIndex) {
					newYpos = rollPosHistory[myHistoryIndex];
				} else {
					newYpos = rollPosHistory[0];
				}
				
				waveFormYpos[iVoice] = (rollPosSmoothing*waveFormYpos[iVoice])+((1.0-rollPosSmoothing)*newYpos);
				
				if (iVoice > 0) {
					waveFormYpos[iVoice] = ((rollPosSmoothing*0.1)*waveFormYpos[iVoice-1])+((1.0-(rollPosSmoothing*0.1))*waveFormYpos[iVoice]); 
				}
				
				NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
				
				if (PropB(waveOnStr)) {
					ofxPoint2f * startP = new ofxPoint2f(0,waveFormYpos[iVoice]);
					ofxPoint2f * endP = new ofxPoint2f(1.0*[self aspect],waveFormYpos[iVoice]);
					[self drawWave:iVoice from:startP to:endP];
					delete startP;
					delete endP;
				}
			}
			
		} glPopMatrix();
		ofEnableAlphaBlending();

		ofSetColor(0,0,0,255);
		ofFill();
		
		float backLine = [GetPlugin(SceneX) getBackline:(int)round(PropF(@"backlineNo"))];
		
		ofRect(-2.0, backLine, 4.0+[self aspect], -2.0); // top
		ofRect(-2.0, 1.0, 4.0+[self aspect], 2.0); // bottom
		ofRect(-2.0, backLine, 2.0, 4.0+backLine); // left
		ofRect([self aspect], backLine, 4.0+[self aspect], 4.0+backLine); // right
		
		
	} PopSurface();
	
}

-(void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end{
	
	float backLine = [GetPlugin(SceneX) getBackline:(int)round(PropF(@"backlineNo"))];

	begin->y = ofMap(begin->y, 0, 1, backLine , 1,false);
	end->y = begin->y;
	
	ofxVec2f v1 = ofxVec2f(end->x, end->y)-ofxVec2f(begin->x, begin->y);
	ofxVec2f v2 = ofxVec2f(0,1.0);
	
	float length = v1.length();
	
	float texWidth = gradient.width;
	float texXstep = texWidth/(NUM_VOICES+1);
	float texHeight = gradient.height;
	
	ofFill();	
	
	//		glTranslated(begin->x,begin->y, 0);
	//		glRotated(-v1.angle(v2)+90, 0, 0, 1);
	
	int resolution = PropI(@"resolution");
	float amplitude = PropF(@"amplitude");
	
	ofxPoint2f oldP = ofxPoint2f(0.0, 0.0);	
	
	for (int i = 0;i < resolution; i++) {
		float xStep = 1.0/(resolution-1);
		float x = xStep * i;
		float y = waveForm[iVoice]->sampleAt(x)*amplitude;
		float texXstart = texXstep * iVoice;
		
		ofxPoint2f p = ofxPoint2f(x*length, begin->y+y);
		if(i > 0){
			gradient.getTextureReference().bind();
			
			glBegin(GL_QUADS);
			
			glTexCoord2f(texXstart+(texXstep*(p.x/length)),0);	glVertex2f(p.x, backLine);

			glTexCoord2f(texXstart+(texXstep*(oldP.x/length)),0);	glVertex2f(oldP.x, backLine);

			glTexCoord2f(texXstart+(texXstep*(oldP.x/length)),texHeight);	glVertex2f(oldP.x, oldP.y);

			glTexCoord2f(texXstart+(texXstep*(p.x/length)),texHeight);	glVertex2f(p.x, p.y);

			glEnd();
			gradient.getTextureReference().unbind();
		}
		
		oldP = p;
	}
	
}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}



@end
