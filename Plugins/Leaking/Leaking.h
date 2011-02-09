#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"

#define NUMPOINTS 40

struct RPoint {
	ofxPoint2f pos;
	ofxVec2f f;
	ofxVec2f v;
};

@interface Rubber : NSObject
{
	vector<RPoint> points;
	
	NSNumber * elasticForce;
	NSNumber * damping;
	NSNumber * pullForce;
	NSNumber * speed;
	
	vector<ofxPoint2f> lastPointsIn;

}

@property (readwrite, retain) NSNumber * elasticForce;
@property (readwrite, retain) NSNumber * damping;
@property (readwrite, retain) NSNumber * pullForce;
@property (readwrite, retain) NSNumber * speed;

-(void) updateWithPoints:(vector<ofxPoint2f>) points;

-(void) updateWithTimestep:(float)time;

@end


@interface Leaking : ofPlugin {
	float mousex,mousey,mouseh;
	
	bool clear;
	
	NSMutableArray * rubbers;
	
	int timeout;
}

-(float) aspect;
@end
