#import "Leaking.h"
#import "Kinect.h"
#import "Keystoner.h"


@implementation Rubber

@synthesize elasticForce, damping, pullForce, speed;

-(id) init{
	if([super init]){
		for(int i=0;i<NUMPOINTS;i++){
			float r = TWO_PI*(float)i/NUMPOINTS;
			ofxPoint2f p = 	ofxPoint2f(0.2,0.5) + ofxPoint2f(sin(r), cos(r))*0.3;
			RPoint newP;
			newP.pos = p;
			
			points.push_back(newP);
		}
	}
	return self;
}

-(void) updateWithPoints:(vector<ofxPoint2f>) pointsIn{
	//points.clear();
	/*	for(int i=0;i<pointsIn.size();i++){
	 if(i >= points.size()){
	 points.push_back(pointsIn[i]);
	 }
	 }*/
	vector<ofPoint> poly;
	for(int i=0;i<points.size();i++){
		poly.push_back(points[i].pos);
	}
	
	for(int i=0;i<pointsIn.size();i++){
		if(!ofInsidePoly(pointsIn[i].x, pointsIn[i].y, poly)){
			//Find nærmeste punkt
			float bestDist = -1;
			RPoint * bestPoint;
			for(int j=0;j<points.size();j++){
				ofxVec2f v = points[j].pos - pointsIn[i];
				if(bestDist == -1 || bestDist > v.length()){
					bestPoint = &points[j];
					bestDist = v.length();
				}
			}
			if(bestPoint != nil){
				ofxVec2f v = bestPoint->pos - pointsIn[i];
				bestPoint->f += -v*[[self pullForce] floatValue]*1.0/(pointsIn.size()/100.0);
			}
		} 
	}
	
	lastPointsIn = pointsIn;
}

-(void) updateWithTimestep:(float)time{
	
	for(int j=0;j<200;j++){
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
			
			point->pos += point->v*time;
			
			
		}	
	}
	
	for(int i=0;i<points.size();i++){
		RPoint * point = &points[i];
		point->f = ofxVec2f();		
	}

}	

-(void) draw{
	ofSetColor(255, 255, 255);
	glBegin(GL_LINE_STRIP);
	for(int i=0;i<points.size();i++){
		glVertex2d(points[i].pos.x, points[i].pos.y);
	}
	glEnd();
	
	ofSetColor(255, 0, 0);
	
	glBegin(GL_POINTS);
	for(int i=0;i<lastPointsIn.size();i++){
		glVertex2d(lastPointsIn[i].x, lastPointsIn[i].y);
	}
	glEnd();
}

@end


@implementation Leaking

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"state"];	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"clear"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:5.0 minValue:0.0 maxValue:2.0] named:@"elasticForce"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1.0] named:@"damping"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.03 minValue:0.0 maxValue:0.12] named:@"pullForce"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.03 minValue:0.0 maxValue:10] named:@"speed"];	
	
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
	if(clear){
		clear = NO;
	}
	
	vector<ofxPoint3f> points = [GetPlugin(Kinect) getPointsInBoxXMin:0 xMax:[self aspect] yMin:0 yMax:10000 zMin:0 zMax:0.6 res:37];
	if(points.size() > 0){
		cout<<points.size()<<endl;
		vector<ofxPoint2f> points2;
		for(int i=0;i<points.size();i++){
			points2.push_back(ofxPoint2f(points[i].x, points[i].z));
		}
		
		
		Rubber * r;
		if(timeout > 30){
			r = [[Rubber alloc] init];
			[r bind:@"elasticForce" toObject:self withKeyPath:@"properties.elasticForce" options:nil];
			[r bind:@"damping" toObject:self withKeyPath:@"properties.damping" options:nil];
			[r bind:@"pullForce" toObject:self withKeyPath:@"properties.pullForce" options:nil];
			[r bind:@"speed" toObject:self withKeyPath:@"properties.speed" options:nil];
			
			[rubbers addObject:r];
		} else {
			r = [rubbers lastObject];
		}
		[r updateWithPoints:points2];
		
		timeout = 0;
		
		
	}
	
	
	if(mouseh >= 0){
		
		vector<ofxPoint2f> points;
		points.reserve(100);
		for(int i=0;i<100;i++){
			float r = TWO_PI*i/100.0;
			float s = 0.09;
			points.push_back(ofxPoint2f(mousex*[self aspect],mousey)+ ofxPoint2f(cos(r)*s,sin(r)*s));
		}
		
		Rubber * r;
		if(timeout > 30){
			r = [[Rubber alloc] init];
			[r bind:@"elasticForce" toObject:self withKeyPath:@"properties.elasticForce" options:nil];
			[r bind:@"damping" toObject:self withKeyPath:@"properties.damping" options:nil];
			[r bind:@"pullForce" toObject:self withKeyPath:@"properties.pullForce" options:nil];
			[r bind:@"speed" toObject:self withKeyPath:@"properties.speed" options:nil];
			
			[rubbers addObject:r];
		} else {
			r = [rubbers lastObject];
		}
		[r updateWithPoints:points];
		
		timeout = 0;
	}
	timeout ++;
	
	for(Rubber * r in rubbers){
		[r updateWithTimestep:60.0/ofGetFrameRate()];
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	ApplySurface(@"Floor");
	for(Rubber * r in rubbers){		
		[r draw];
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
