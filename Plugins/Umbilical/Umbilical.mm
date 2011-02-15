#import "Umbilical.h"
#import "Keystoner.h"
#import "Kinect.h"
#import "Wave.h"

@implementation Umbilical

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1000.0] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:100.0 minValue:-100.0 maxValue:100.0] named:@"drift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-1.0 maxValue:1.0] named:@"direction"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:8.0] named:@"waveChannel"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0.0 maxValue:1.0] named:@"startPosX"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"startPosY"];
}

-(void) setup{
	
	distortion = new MSA::Interpolator1D;
	distortion->reserve((int)roundf(PropF(@"resolution")));
	mousex = 0.5;
	mousey = 0.0;
}

-(void) update:(NSDictionary *)drawingInformation{
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	wave = [GetPlugin(Wave)
			getWaveFormWithIndex:(int)roundf(PropF(@"waveChannel"))
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
		for (int i=distortion->size()-1; i >= 0 ; i--) {
			newDistortion->push_back(distortion->getData()[i]);
		}
		distortion->clear();
		distortion = newDistortion;
	}
	
	if ([wave count] > 0) {
		for (int i=0; i < fabs(direction); i++) {
			distortion->push_back([[wave objectAtIndex:0] floatValue]);
		}
	}
	
	if (distortion->size() > resolution) {
		MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
		newDistortion->reserve(resolution);
		for (int i=distortion->size()-resolution; i < distortion->size() ; i++) {
			newDistortion->push_back(distortion->getData()[i]);
		}
		distortion->clear();
		distortion = newDistortion;
	}
	
	if(direction < 0){
		MSA::Interpolator1D * newDistortion = new MSA::Interpolator1D;
		newDistortion->reserve(resolution);
		for (int i=distortion->size()-1; i >= 0 ; i--) {
			newDistortion->push_back(distortion->getData()[i]);
		}
		distortion->clear();
		distortion = newDistortion;
	}
	
	startPos = ofxVec2f(PropF(@"startPosX"), PropF(@"startPosY"));
	
	if(mouseh < 0){
		
		NSMutableArray * pblobs = [GetPlugin(Kinect) persistentBlobs];
		
		if([pblobs count] >= 1){
			PersistentBlob * oldest = nil;
			for(PersistentBlob * b in pblobs){
				if(oldest == nil || b->age > oldest->age)
					oldest = b;
			}
			if(oldest != nil){
				endPos = ofxVec2f(oldest->centroidFiltered->x,oldest->centroidFiltered->y);
			}
		}
		
	} else {
		endPos = ofxVec2f(mousex,mousey);
	}
	
}

-(void) draw:(NSDictionary*)drawingInformation{
	ApplySurface(@"Floor");{
		
		ofxVec2f v1 = endPos-startPos;
		v1.x *=[self aspect];
		ofxVec2f v2 = ofxVec2f(0,1.0*[self aspect]);
		
		float length = v1.length();
		
		glPushMatrix();{
			
			ofNoFill();
			ofSetLineWidth(1.5);
			
			ofSetColor(255, 255, 255, 255);
			
			glTranslated(startPos.x*[self aspect],startPos.y, 0);
			glRotated(-v1.angle(v2)+90, 0, 0, 1);
						
			int segments = distortion->size();
			float amplitude = PropF(@"amplitude");
			
			glBegin(GL_LINE_STRIP);
			
			for (int i = 0;i< segments; i++) {
				float x = 1.0/segments*i;
				float envelope = (1.0-powf((1.0-sqrt(x)),5.0))*(1.0-powf((1.0-sqrt(-x+1)),5.0));
				glVertex2f(x*length, distortion->getData()[i]*amplitude*envelope);
			}
			glEnd();
			
		} glPopMatrix();
		
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
		ofEllipse(mousex*200.0, mousey*400.0, 15, 15);
	}

	ofSetColor(255, 0, 255,100);
	ofEllipse(startPos.x*200, startPos.y*400, 15, 15);
	ofEllipse(endPos.x*200, endPos.y*400, 15, 15);

	ofxVec2f v1 = endPos-startPos;
	v1.x *=[self aspect];
	ofxVec2f v2 = ofxVec2f(0,1.0*[self aspect]);
	
	float length = v1.length();
	
	glPushMatrix();{
	
		ofNoFill();
		ofSetLineWidth(1.5);
		
		ofSetColor(255, 255, 255, 255);
		
		glScaled(400, 400, 0);
		
		glTranslated(0.5*[self aspect],0, 0);
		glRotated(-v1.angle(v2)+90, 0, 0, 1);
				
		int segments = distortion->size();
		float amplitude = PropF(@"amplitude");
		
		glBegin(GL_LINE_STRIP);
		
		for (int i = 0;i< segments; i++) {
			float x = 1.0/segments*i;
			float envelope = (1.0-powf((1.0-sqrt(x)),5.0))*(1.0-powf((1.0-sqrt(-x+1)),5.0));
			glVertex2f(x*length, distortion->getData()[i]*amplitude*envelope);
		}
		glEnd();
		
	} glPopMatrix();
	
	
}

-(void) controlMousePressed:(float)x y:(float)y button:(int)button{
	mousex = x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseDragged:(float)x y:(float)y button:(int)button{
	mousex = x / 200.0;
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
