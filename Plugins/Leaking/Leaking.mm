#import "Leaking.h"
#import "Kinect.h"
#import "Keystoner.h"
#include <dispatch/dispatch.h>


@implementation Rubber

@synthesize elasticForce, damping, pullForce, speed, border, pushForceInternal, pushForceExternal, pushForceInternalDist, pushForceExternalDist;;

-(id) initWithPoints:(vector<ofxPoint2f>) _points{
	if([self init]){
		//Find center
		ofxPoint2f center;
		for(int i=0;i<_points.size();i++){
			center += _points[i];
		}
		center /= _points.size();
		
		for(int i=0;i<NUMPOINTS;i++){
			float r = TWO_PI*(float)i/NUMPOINTS;
			ofxPoint2f p = 	center + ofxPoint2f(sin(r), cos(r))*0.03;
			RPoint newP;
			newP.pos = p;
			
			newP.filterX.setNl(9.413137469932821686e-04, 2.823941240979846506e-03, 2.823941240979846506e-03, 9.413137469932821686e-04);
			newP.filterX.setDl(1, -2.5818614306773719263, 2.2466666427559748864, -.65727470210265670262);
			newP.filterY.setNl(9.413137469932821686e-04, 2.823941240979846506e-03, 2.823941240979846506e-03, 9.413137469932821686e-04);
			newP.filterY.setDl(1, -2.5818614306773719263, 2.2466666427559748864, -.65727470210265670262);
			
			newP.filterX.setStartValue(p.x);
			newP.filterY.setStartValue(p.y);			
			
			points.push_back(newP);
		}
	}
	return self;
}

//Returns stroked point
-(ofxPoint2f) innerPoint:(int)i{
	RPoint * point = &points[i];
	RPoint * prevPoint, * nextPoint;
	if(i == 0){
		prevPoint = &points[points.size()-1];
		nextPoint = &points[i+1];
	} else if(i == points.size()-1){
		prevPoint = &points[i-1];
		nextPoint = &points[0];		
	} else {
		prevPoint = &points[i-1];
		nextPoint = &points[i+1];		
	}
	
	ofxVec2f v = nextPoint->pos - prevPoint->pos;
	v = -ofxVec2f(-v.y,v.x).normalized()*[[self border] floatValue]*0.1;
	
	return point->pos+v;
	
}

-(ofxPoint2f) centroid{
	ofxPoint2f c;
	for(int i=0;i<points.size();i++){
		c += points[i].pos;	
	}
	c /= points.size();
	return c;
}

-(void) updateWithPoints:(vector<ofxPoint2f>) pointsIn{	
	vector<ofPoint> poly;
	for(int i=0;i<points.size();i+=2){
		poly.push_back(points[i].pos);
	}
	
	const int N = pointsIn.size();	
	bool inPoly[N];
	memset(inPoly, 0, N);
	
	
	for(int i=0;i<N;i++){		
		if(ofInsidePoly(pointsIn[i].x, pointsIn[i].y, poly)){
			inPoly[i] = true;
		}
	}		
	
	float _pullForce = [[self pullForce] floatValue];
	
	for(int i=0;i<N;i++){
		if(!inPoly[i]){
			int pointsJumper = 19;
			
			//Find nærmeste punkt
			float bestDist = -1;
			RPoint * bestPoint;
			int bestJ1;
			
			//Tager først en hurtig tur rundt og finder den bedste
			for(int j=0;j<points.size();j+=pointsJumper){
				float d = points[j].pos.distanceSquared(pointsIn[i]) ;
				if(bestDist == -1 || bestDist > d){
					bestPoint = &points[j];
					bestDist = d;
					bestJ1 = j;
				} 
			}
			
			pointsJumper = 5;
			int searchDist = 20;
			
			int bestJ2 = bestJ1;
			for(int s=0;s<2;s++){				
				//Har nu en cirka punkt. Søger nu rundt om den
				for(int j=bestJ1+1;j<bestJ1+searchDist;j+=pointsJumper){
					int realJ = j;
					if(realJ >= points.size())
						realJ -= points.size();
					
					float d = points[j].pos.distanceSquared(pointsIn[i]) ;
					if(bestDist > d){
						bestPoint = &points[j];
						bestDist = d;
						bestJ2 = j;
					} 
				}
				for(int j=bestJ1-1;j>bestJ1-searchDist;j-=pointsJumper){
					int realJ = j;
					if(realJ < 0)
						realJ += points.size();
					
					float d = points[j].pos.distanceSquared(pointsIn[i]) ;
					if(bestDist > d){
						bestPoint = &points[j];
						bestDist = d;
						bestJ2 = j;
					} 
				}
				bestJ1 = bestJ2;
				pointsJumper = 1;
				searchDist = 3;
			}	
			/*		
			 for(int j=0;j<points.size();j+=1){
			 float d = points[j].pos.distanceSquared(pointsIn[i]) ;
			 if(bestDist == -1 || bestDist > d){
			 bestPoint = &points[j];
			 bestDist = d;
			 } 
			 }*/
			if(bestPoint != nil){
				ofxVec2f v = bestPoint->pos - pointsIn[i];
				bestPoint->f += -0.01*v*_pullForce*1.0/(pointsIn.size()/100.0);
			}
		} 
	}
	
	lastPointsIn = pointsIn;
}

-(void) updateForceToOtherObjects:(NSArray*)array{
	float internalPushForceDist = [[self pushForceInternalDist] floatValue];
	float externalPushForceDist = [[self pushForceExternalDist] floatValue];
	float internalPushForce = [[self pushForceInternal] floatValue];
	float externalPushForce = [[self pushForceExternal] floatValue];
	
	//Find punkter der er inde i den anden
	int pointsJumper = 5;
	vector<ofPoint> poly;
	for(int i=0;i<points.size();i+=pointsJumper){
		poly.push_back(points[i].pos);
	}
	
	
	for (Rubber * obj in array) {
		bool isSelf = (obj == self);
		
		if(!isSelf){
			ofxPoint2f center = [obj centroid];
			bool centerInPoly = ofInsidePoly(center.x, center.y, poly);
			
			ofxVec2f centerGoal;
			if(centerInPoly){
				ofxVec2f v = center - [self centroid];
				centerGoal = center + v;
			}
			
			//Gå igennem alle punkter for at se om nogen er inde i en anden blob
			for(int u=0;u<obj->points.size();u++){
				RPoint * pThat = &obj->points[u];
				if(ofInsidePoly(pThat->pos.x, pThat->pos.y, poly)){
					ofxPoint2f goal;
					if(centerInPoly){
						goal = centerGoal;
					} else {
						goal = center;
					}
					pThat->f += 0.01*(goal - pThat->pos);
				}
			}
		}
		
		bool proceed = false;
		if(!isSelf){
			//Laver en hurtig søgnin for at se om der er noget der ligner der er tæt på hinanden hvis det er et andet object
			float shortestDist = -1;
			int bestI, bestU;
			for(int i=0;i<points.size();i+=10){
				RPoint * pThis = &points[i];
				
				for(int u=0;u<obj->points.size();u+=10){
					RPoint * pThat = &obj->points[u];
					float d = pThat->pos.distanceSquared(pThis->pos);
					if(shortestDist == -1 || d < shortestDist){
						shortestDist = d;
						bestI = i;
						bestU = u;
					}
				}
			}

			if(shortestDist < externalPushForceDist*externalPushForceDist ){
				proceed = YES;
			}
		} else {
			proceed = YES;
		}
		
		
		if(proceed){
			for(int i=0;i<points.size();i++){
				RPoint * pThis = &points[i];
				for(int u=0;u<obj->points.size();u++){
					RPoint * pThat = &obj->points[u];
					if( i!=u || !isSelf ){
						ofxVec2f v = pThis->pos - pThat->pos;
						float d = v.length();
						if(isSelf){
							if(d < internalPushForceDist){
								d *= 1.0/internalPushForceDist;
								
								float f = -d+1;
								v.normalize();
								float s = 0.00001;
								pThat->f -= f*v*s*internalPushForce;		
								
							}
							
						} else {
							if(d < externalPushForceDist){
								d *= 1.0/externalPushForceDist;
								
								float f = -d+1;
								v.normalize();
								float s = 0.0001;
								pThat->f -= f*v*s*externalPushForce;		
								
							}							
						}
					}				
				}
			}
		}	
	}
}

-(void) updateWithTimestep:(float)time{
	
	RPoint * prevPoint = &points[points.size()-1];
	for(int i=0;i<points.size();i++){
		RPoint * point = &points[i];	
		
		ofxVec2f v = prevPoint->pos - point->pos;
		
		v *= [[self elasticForce] floatValue]*1.0/20.0;
		
		point->f += v;
		prevPoint->f -= v;
		
		prevPoint = point;
	}	
	
	
	for(int i=0;i<points.size();i++){
		RPoint * point = &points[i];	
		point->v *= [[self damping] floatValue];
		point->v += point->f*[[self speed] floatValue];
		
		point->v.limit(0.01);
		
		ofxPoint2f p = point->pos + point->v*time;
		p.x = ofClamp(p.x, 0, aspect);
		p.y = ofClamp(p.y, 0, 1);
		
		point->pos = p;		
	}	
	
	for(int i=0;i<points.size();i++){
		RPoint * point = &points[i];
		point->f = ofxVec2f();		
	}
	
}	

-(void) calculateFilteredPos{
	for(int i=0;i<points.size();i++){
		RPoint * point = &points[i];
		
		point->filteredPos.x =  point->filterX.filter(point->pos.x);
		point->filteredPos.y =  point->filterY.filter(point->pos.y);		
	}	
}

-(void) draw{
	ofSetColor(0, 100, 0);
	glBegin(GL_LINE_STRIP);
	for(int i=0;i<points.size();i++){
		glVertex2d(points[i].pos.x, points[i].pos.y);
	}
	glEnd();
	
	ofSetColor(255, 255, 255);
	glBegin(GL_LINE_STRIP);
	for(int i=0;i<points.size();i++){
		glVertex2d(points[i].filteredPos.x, points[i].filteredPos.y);
	}
	glEnd();
	
	/*ofSetColor(255, 0, 0);
	 
	 glBegin(GL_POINTS);
	 for(int i=0;i<lastPointsIn.size();i++){
	 glVertex2d(lastPointsIn[i].x, lastPointsIn[i].y);
	 }
	 glEnd();*/
}

@end


@implementation Leaking

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"state"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2000] named:@"yMax"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2000] named:@"goodPointMaxY"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"goodBadFactor"];	
	
	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"clear"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:1.0] named:@"enableKinect"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:5.0 minValue:0.0 maxValue:0.2] named:@"elasticForce"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1.0] named:@"damping"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.03 minValue:0.0 maxValue:0.1] named:@"pullForce"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.03 minValue:0.0 maxValue:10] named:@"speed"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0.0 maxValue:10] named:@"border"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:0.2] named:@"pushForceInternal"];			
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:2] named:@"pushForceExternal"];			
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.2 minValue:0.01 maxValue:1.0] named:@"pushForceInternalDist"];			
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.2 minValue:0.01 maxValue:1.0] named:@"pushForceExternalDist"];			
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1.0 maxValue:500] named:@"iterations"];		
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:100 minValue:1.0 maxValue:500] named:@"KinectRes"];			
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1.0 maxValue:10] named:@"filterPasses"];			
	
	
	mouseh = -1;
	rubbers = [NSMutableArray array];
	timeout = 100;
}

-(void) setup{
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"clear") && [object boolValue]){
		clear = true;
		[object setBoolValue:NO];		
	}
}


-(void) update:(NSDictionary *)drawingInformation{
	goodPoints.clear();
	badPoints.clear();
	
	if(clear){
		
		[rubbers removeAllObjects];
		timeout = 100;
		clear = NO;
	}
	
	vector<ofxPoint2f> points;
	
	
	if(PropB(@"enableKinect")){
		vector<ofxPoint3f> pointsKinect = [GetPlugin(Kinect) getPointsInBoxXMin:0 xMax:[self aspect] yMin:0 yMax:PropI(@"yMax") zMin:0 zMax:0.8 res:PropI(@"KinectRes")];
		if(pointsKinect.size() > 0){
			for(int i=0;i<pointsKinect.size();i++){				
				if(pointsKinect[i].y > PropF(@"goodPointMaxY"))
					badPoints.push_back(ofxPoint2f(pointsKinect[i].x, pointsKinect[i].z));
				else {
					
					goodPoints.push_back(ofxPoint2f(pointsKinect[i].x, pointsKinect[i].z));	
				}
				
				points.push_back(ofxPoint2f(pointsKinect[i].x, pointsKinect[i].z));
			}		
			if(badPoints.size() / (float) goodPoints.size() > PropF(@"goodBadFactor"))
				points.clear();
		}
	}
	
	if(mouseh > 0){		
		points.reserve(100);
		for(int i=0;i<100;i++){
			float r = TWO_PI*i/100.0;
			float s = 0.09;
			points.push_back(ofxPoint2f(mousex*[self aspect],mousey)+ ofxPoint2f(cos(r)*s,sin(r)*s));
		}
	} else if(mouseh == 0){
		for(int i=0;i<100;i++){
			float r = TWO_PI*i/100.0;
			float s = 0.09;
			//	storedPoints.push_back(ofxPoint2f(mousex*[self aspect],mousey)+ ofxPoint2f(cos(r)*s,sin(r)*s));
		}
		
	}
	
	
	
	Rubber * updateRubber;
	if(points.size() > 0){
		if(timeout > 30){
			updateRubber = [[Rubber alloc] initWithPoints:points];
			[updateRubber bind:@"elasticForce" toObject:self withKeyPath:@"properties.elasticForce" options:nil];
			[updateRubber bind:@"damping" toObject:self withKeyPath:@"properties.damping" options:nil];
			[updateRubber bind:@"pullForce" toObject:self withKeyPath:@"properties.pullForce" options:nil];
			[updateRubber bind:@"speed" toObject:self withKeyPath:@"properties.speed" options:nil];
			[updateRubber bind:@"border" toObject:self withKeyPath:@"properties.border" options:nil];
			[updateRubber bind:@"pushForceInternal" toObject:self withKeyPath:@"properties.pushForceInternal" options:nil];
			[updateRubber bind:@"pushForceExternal" toObject:self withKeyPath:@"properties.pushForceExternal" options:nil];			
			[updateRubber bind:@"pushForceInternalDist" toObject:self withKeyPath:@"properties.pushForceInternalDist" options:nil];
			[updateRubber bind:@"pushForceExternalDist" toObject:self withKeyPath:@"properties.pushForceExternalDist" options:nil];			
			updateRubber->aspect = [self aspect];
			
			
			for(int i=0;i<500;i++){
				[updateRubber updateWithPoints:points];
				[updateRubber updateWithTimestep:60.0/ofGetFrameRate()];				
				[updateRubber calculateFilteredPos];
				
			}
			
			[rubbers addObject:updateRubber];
		} else {
			updateRubber = [rubbers lastObject];
		}
		timeout = 0;
	}
	
	
	
	if(points.size() > 150){
		points.erase(points.begin(),points.begin()+points.size()-150);
	}
	
	for(Rubber * r in rubbers){
		[r updateForceToOtherObjects:rubbers];
	}
	for(int i=0;i<PropI(@"iterations");i++){
		for(Rubber * r in rubbers){
			if(r == updateRubber){
				[r updateWithPoints:points];
			}
			
			[r updateWithTimestep:60.0/ofGetFrameRate()];
		}
		
	}
	
	
	
	
	for(int i=0;i<PropI(@"filterPasses");i++){
		for(Rubber * r in rubbers){
			[r 	calculateFilteredPos];
		}
	}
	
	
	
	
	
	timeout ++;
	
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	ApplySurface(@"Floor");
	for(Rubber * r in rubbers){		
		[r draw];
	}
	
	ofSetColor(0, 255, 0);
	for(int i=0;i<goodPoints.size();i++){
		ofRect(goodPoints[i].x, goodPoints[i].y, 0.01, 0.01);
	}
	
	ofSetColor(255, 0, 0);
	for(int i=0;i<badPoints.size();i++){
		ofRect(badPoints[i].x, badPoints[i].y, 0.01, 0.01);
	}
	
	PopSurface();
	
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
	
	glPushMatrix();
	glScaled(200*1.0/[self aspect], 400, 1);
	for(Rubber * r in rubbers){
		
		[r draw];
	}
	glPopMatrix();
	
	ofSetColor(255, 255,0);
	ofDrawBitmapString("Number rubbers: "+ofToString([rubbers count], 0), 10, 10);
	
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
