#import "Umbilical.h"
#import "Keystoner.h"
#import "Kinect.h"

@implementation Umbilical



-(float) falloff:(float)p{
	if(p >= 1)
		return 1;
	if(p<=0)
		return 0;
	p *= 6;
	p -= 3;
	
	return 1.0/(1.0+pow(5,-p));
}

-(float) offset:(float)x{
	float xScale = 50.0;
	x *= xScale;
	float u = endPos.y*xScale;
	float s = 5;
	float e = 2.71828182845904523536;
	return 20 * (pow(e , -(x-u)/s) )/ pow(s*(1+pow(e , -(x-u)/s)) , 2);
	
}

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1000.0] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:100.0 minValue:-100.0 maxValue:100.0] named:@"drift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-1.0 maxValue:1.0] named:@"direction"];
	for (int i = 0; i < NUM_VOICES+1; i++) {
		[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named: 
		 [NSString stringWithFormat:@"wave%iOn",i]
		 ];
		[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUM_VOICES] named:
		 [NSString stringWithFormat:@"wave%iChannel",i]
		 ];
	}
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0.0 maxValue:1.0] named:@"startPosX"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"startPosY"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.01 minValue:0.01 maxValue:1.0] named:@"falloffStart"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.01 minValue:0.01 maxValue:1.0] named:@"falloffEnd"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"weighLiveOrBuffer"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUM_VOICES] named:@"numberOfFixedStrings"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"stretch"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"endpointPushForce"];
}

-(void) setup{	
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		distortion[i] = new MSA::Interpolator1D;
		distortion[i]->reserve((int)roundf(PropF(@"resolution")));
		waveForm[i] =  new MSA::Interpolator1D;
		waveForm[i]->reserve((int)roundf(PropF(@"resolution")));
		
		bool notOk = true;
		while(notOk){
			notOk = false;
			waveX[i] = ofRandom(0, [self aspect]);
			for(int j=0;j<i;j++){
				if(fabs(waveX[i] - waveX[j]) < 0.02){
					notOk = true;
					cout<<"Damn "<<waveX[i]<<"  "<<waveX[j]<<endl;
				}
			}
		}		
	}
	
	mousex = 0.5;
	mousey = 0.0;
}

-(void) update:(NSDictionary *)drawingInformation{
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
		//Offsets
		{
			while(offsets[iVoice].size() < PropI(@"resolution"))
				offsets[iVoice].push_back(0);
			
			float midDist =  fabs(0.5*[self aspect] - waveX[iVoice]);
			for(int i=0;i<PropI(@"resolution");i++){
				float x = (float)i/PropI(@"resolution");
				float offset = 0;			
				if(PropF(@"endpointPushForce") > 0){
					//Ved det er snyd, men skal finde afstand til endpoint, og snyder
					ofxPoint2f thisPoint = ofxPoint2f(waveX[iVoice], x);
					float dir = 1;
					if(thisPoint.x < 0.5*[self aspect])
						dir = -1;
					
					float xDist = dir*(endPos.x - thisPoint.x)+0.1;
					
					float d = fabs(0.5*[self aspect] - endPos.x)+0.05;
					
					if(xDist > 0){
						offset = -dir*PropF(@"endpointPushForce") * 100 * [self offset:x] * d * xDist;
					} else {
						offset = -dir*PropF(@"endpointPushForce") * 100 * [self offset:x] * d * (xDist)*0.8;
						//offset = xDist;
					}
					
				}
				

				offsets[iVoice][i] += (offset - offsets[iVoice][i]) * pow([self aspect]*0.5 - midDist,2)*9;
			}
		}
		
		
		NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
		
		if (iVoice > 0) {
			if (iVoice-1 < NUM_VOICES-PropF(@"numberOfFixedStrings")){
				[[properties objectForKey:waveOnStr] setBoolValue:YES];
			} else {
				[[properties objectForKey:waveOnStr] setBoolValue:NO];
			}
			
		}
		
		if (PropB(waveOnStr)) {
			
			NSString * waveChannelStr = [NSString stringWithFormat:@"wave%iChannel",iVoice];
			
			wave = [GetPlugin(Wave)
					getWaveFormWithIndex:(int)roundf(PropF(waveChannelStr))
					amplitude:1.0 
					driftSpeed:PropF(@"drift")
					smoothing:PropF(@"smoothing")
					freqeuncy:PropF(@"frequency")
					random:0
					];
			
			float direction = PropF(@"direction");
			
			if(direction < 0){
				MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
				newDistortion->reserve(resolution);
				for (int i=distortion[iVoice]->size()-1; i >= 0 ; i--) {
					newDistortion->push_back(distortion[iVoice]->getData()[i]);
				}
				distortion[iVoice]->clear();
				distortion[iVoice] = newDistortion;
			}
			
			if ([wave count] > 0) {
				if(fabs(direction) > 0) {
					distortion[iVoice]->push_back([[wave objectAtIndex:0] floatValue]);
				}
				waveForm[iVoice]->clear();
				for (int i=0; i < [wave count]; i++) {
					waveForm[iVoice]->push_back([[wave objectAtIndex:i] floatValue]);
				}
			}
			
			if (distortion[iVoice]->size() > resolution) {
				MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
				newDistortion->reserve(resolution);
				for (int i=distortion[iVoice]->size()-resolution; i < distortion[iVoice]->size() ; i++) {
					newDistortion->push_back(distortion[iVoice]->getData()[i]);
				}
				distortion[iVoice]->clear();
				distortion[iVoice] = newDistortion;
			}
			
			if(direction < 0){
				MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
				newDistortion->reserve(resolution);
				for (int i=distortion[iVoice]->size()-1; i >= 0 ; i--) {
					newDistortion->push_back(distortion[iVoice]->getData()[i]);
				}
				distortion[iVoice]->clear();
				distortion[iVoice] = newDistortion;
			}
			
		} else {
			//Tøm bufferen forfra hvis den er slået fra
			MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
			newDistortion->reserve(resolution);
			for (int i=1; i < distortion[iVoice]->size() ; i++) {
				newDistortion->push_back(distortion[iVoice]->getData()[i]);
			}
			distortion[iVoice]->clear();
			distortion[iVoice] = newDistortion;			
		}	
		
	}
	
	
	startPos = ofxVec2f(PropF(@"startPosX"), PropF(@"startPosY"));
	
	if(mouseh < 0){
		
		NSMutableArray * pblobs = [GetPlugin(Kinect) persistentBlobs];
		
		if([pblobs count] >= 1){
			PersistentBlob * oldest = nil;
			for(PersistentBlob * b in pblobs){
				if((oldest == nil || b->age > oldest->age) && [b centroidFiltered].x > 0 && [b centroidFiltered].x < [self aspect])
					oldest = b;
			}
			if(oldest != nil){
				endPos = ofxVec2f([oldest centroidFiltered].x,[oldest centroidFiltered].z);
			}
		}
		
	} else {
		endPos = ofxVec2f(mousex,mousey);
	}
	
	
	
}


-(void) drawWave:(int)iVoice from:(ofxPoint2f)begin to:(ofxPoint2f)end{
	ofxVec2f v1 = end-begin;
	ofxVec2f v2 = ofxVec2f(0,1.0);
	
	float length = v1.length();
	
	glPushMatrix();{
		
		ofNoFill();
		ofSetLineWidth(4);
		
		ofSetColor(255, 255, 255, 255);
		
		glTranslated(begin.x,begin.y, 0);
		glRotated(-v1.angle(v2)+90, 0, 0, 1);
		
		int segments = distortion[iVoice]->size();
		int resolution = PropF(@"resolution");
		float amplitude = PropF(@"amplitude");
		float weighLiveOrBuffer = PropF(@"weighLiveOrBuffer");
		
		int startSegment, endSegment;
		
		if (PropB(@"stretch")) {
			startSegment = segments*begin.y;
			endSegment = segments*end.y;
		} else {
			startSegment = resolution*begin.y;
			endSegment = resolution*end.y;
		}
		
		//glBegin(GL_LINE_STRIP);
		glBegin(GL_QUAD_STRIP);
		ofxPoint2f lastPoint = ofxPoint2f(0,0);		
		for (int i = startSegment;i< endSegment; i++) {
			float x = 1.0/(endSegment-startSegment)*(i-startSegment);
			
			if (i < segments) {
				float f = [self falloff:(float)x/PropF(@"falloffStart")] * [self falloff:(1-x)/PropF(@"falloffEnd")];
				ofxPoint2f p = ofxPoint2f(x*length, offsets[iVoice][i]+((distortion[iVoice]->getData()[i]*weighLiveOrBuffer)+(waveForm[iVoice]->sampleAt(x)*(1.0-weighLiveOrBuffer)))*amplitude*f);
				ofxVec2f v = p - lastPoint;
				ofxVec2f h = ofxVec2f(-v.y,v.x);
				h.normalize();
				h *= 0.003;
				glVertex2f((p+h).x, (p+h).y);
				glVertex2f((p-h).x, (p-h).y);				
//				glVertex2f(x*length, offsets[iVoice][i]+((distortion[iVoice]->getData()[i]*weighLiveOrBuffer)+(waveForm[iVoice]->sampleAt(x)*(1.0-weighLiveOrBuffer)))*amplitude*f);
				lastPoint = p;
			}
		}
		glEnd();
		
	} glPopMatrix();
}

-(void) draw:(NSDictionary*)drawingInformation{
	ApplySurface(@"Floor");{
		//	glScaled([self aspect], 1, 1);
		
		[self drawWave:0 from:startPos to:endPos];
		
		for (int iVoice = 1; iVoice < NUM_VOICES+1; iVoice++) {
			ofxVec2f start = ofxVec2f(waveX[iVoice], 0.0);
			ofxVec2f end = ofxVec2f(waveX[iVoice], 1.0);
			[self drawWave:iVoice from:start to:end];
		}
		
		/** interpolation nonsense
		 
		 ofNoFill();
		 ofSetLineWidth(1.5);
		 
		 ofSetColor(0, 64, 172, 127);
		 glBegin(GL_LINE_STRIP);
		 for (int i = 0; i < cord->size(); i++) {
		 MSA::Vec2f v = cord->getData()[i];
		 glVertex2d(v.x, v.y);
		 }
		 glEnd();
		 
		 ofSetLineWidth(2.5);
		 
		 ofSetColor(255, 64, 172, 127);
		 ofBeginShape();
		 int steps = 100;
		 for (int i = 0; i <= steps; i++) {
		 MSA::Vec2f v = cord->sampleAt(1.0*i/steps);
		 ofCurveVertex(v.x, v.y);
		 }
		 ofEndShape(false);
		 **/
		
		
	}PopSurface();
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	ofBackground(0, 0, 0);
	ofEnableAlphaBlending();
	ofSetColor(255, 255, 255);
	
	if(mouseh != -1){
		ofEnableAlphaBlending();
		if(mouseh){
			ofNoFill();
		} else {
			ofFill();
		}
		ofSetColor(255, 255, 0,100);
		ofEllipse(mousex*200.0*(1.0/[self aspect]), mousey*400.0, 15, 15);
	}
	
	ofSetColor(255, 0, 255,100);
	ofEllipse(startPos.x*200*(1.0/[self aspect]), startPos.y*400, 15, 15);
	ofEllipse(endPos.x*200*(1.0/[self aspect]), endPos.y*400, 15, 15);
	
	
	glPushMatrix();{
		
		glScaled(200*1.0/[self aspect], 400, 1);
		[self drawWave:0 from:startPos to:endPos];
		
		for (int iVoice = 1; iVoice < NUM_VOICES+1; iVoice++) {
			ofxVec2f start = ofxVec2f(waveX[iVoice], 0.0);
			ofxVec2f end = ofxVec2f(waveX[iVoice], 1.0);
			[self drawWave:iVoice from:start to:end];
		}
		
	}glPopMatrix();
}

-(void) controlMousePressed:(float)x y:(float)y button:(int)button{
	mousex = [self aspect] * x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseDragged:(float)x y:(float)y button:(int)button{
	mousex = [self aspect] * x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseReleased:(float)x y:(float)y{
	mouseh = -1;	
}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}

@end
