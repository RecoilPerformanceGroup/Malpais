#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"
#include "Filter.h"

#define NUMPOINTS 100

struct RPoint {
	ofxPoint2f pos;
	ofxPoint2f filteredPos;

	ofxVec2f f;
	ofxVec2f v;
	
	Filter filterX,filterY;
};

@interface Rubber : NSObject
{
	@public
	vector<RPoint> points;
	
	NSNumber * elasticForce;
	NSNumber * damping;
	NSNumber * pullForce;
	NSNumber * speed;
	NSNumber * border;
	NSNumber * pushForceInternal;
	NSNumber * pushForceExternal;	
	NSNumber * pushForceInternalDist;
	NSNumber * pushForceExternalDist;
	
	NSNumber * percentageForce;
	
	float aspect;
	
	vector<ofxPoint2f> lastPointsIn;
}

@property (readwrite, retain) NSNumber * elasticForce;
@property (readwrite, retain) NSNumber * damping;
@property (readwrite, retain) NSNumber * pullForce;
@property (readwrite, retain) NSNumber * speed;
@property (readwrite, retain) NSNumber * border;
@property (readwrite, retain) NSNumber * pushForceInternal;
@property (readwrite, retain) NSNumber * pushForceExternal;
@property (readwrite, retain) NSNumber * pushForceInternalDist;
@property (readwrite, retain) NSNumber * pushForceExternalDist;
@property (readwrite, retain) NSNumber * percentageForce;

-(id) initWithPoints:(vector<ofxPoint2f>) points;
-(void) updateWithPoints:(vector<ofxPoint2f>) points;
-(void) updateForceToOtherObjects:(NSArray*)array;
-(void) updateWithTimestep:(float)time;
-(void) calculateFilteredPos;
-(ofxPoint2f) centroid;
-(ofxPoint2f) innerPoint:(int)point;
-(void) debugDraw;

-(bool) pointInsidePoly:(ofxPoint2f)p;

@end


@interface Leaking : ofPlugin {
	float mousex,mousey,mouseh;
	
	bool clear;
	
	NSMutableArray * rubbers;
	
	int timeout;
	
	float goodBadFactor;
	
	vector<ofxPoint3f> goodPoints;
	vector<ofxPoint3f> badPoints;
}

-(float) aspect;
@end
