#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"
#include "ofxOpenCv.h"
#include "Filter.h"

#define NUMPOINTS 50
#define IMGWIDTH 300.0
#define IMGHEIGHT 600.0

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
	NSNumber * elasticLength;
	NSNumber * damping;
	NSNumber * pullForce;
	NSNumber * speed;
	NSNumber * border;
	NSNumber * pushForceInternal;
	NSNumber * pushForceExternal;	
	NSNumber * pushForceInternalDist;
	NSNumber * pushForceExternalDist;
	NSNumber * gravity;

	NSNumber * stiffness;
	NSNumber * massForce;
	NSNumber * percentageForce;
	
	float aspect;
	
	vector<ofxPoint2f> lastPointsIn;
	
	float r,g,b;
	
	
}

@property (readwrite, retain) NSNumber * elasticForce;
@property (readwrite, retain) NSNumber * elasticLength;
@property (readwrite, retain) NSNumber * damping;
@property (readwrite, retain) NSNumber * pullForce;
@property (readwrite, retain) NSNumber * speed;
@property (readwrite, retain) NSNumber * border;
@property (readwrite, retain) NSNumber * pushForceInternal;
@property (readwrite, retain) NSNumber * pushForceExternal;
@property (readwrite, retain) NSNumber * pushForceInternalDist;
@property (readwrite, retain) NSNumber * pushForceExternalDist;
@property (readwrite, retain) NSNumber * percentageForce;
@property (readwrite, retain) NSNumber * gravity;
@property (readwrite, retain) NSNumber * massForce;

@property (readwrite, retain) NSNumber * stiffness;

-(id) initWithPoints:(vector<ofxPoint2f>) points radius:(float)radius;
-(void) updateWithPoints:(vector<ofxPoint2f>) points;
-(void) updateForceToOtherObjects:(NSArray*)array;
-(void) updateWithTimestep:(float)time;
-(void) calculateFilteredPos;
-(ofxPoint2f) centroid;
-(ofxPoint2f) innerPoint:(int)point;
-(void) debugDraw;

-(bool) pointInsidePoly:(ofxPoint2f)p;
-(void) bindTo:(id)obj;
@end


@interface Leaking : ofPlugin {
	float mousex,mousey,mouseh;
	
	bool clear;
	
	NSMutableArray * rubbers;
	
	int timeout;
	
	float goodBadFactor;
	
	float avgDist;
	
	vector<ofxPoint3f> goodPoints;
	vector<ofxPoint3f> badPoints;
	
	ofxCvFloatImage * image;
	ofxCvFloatImage * tmpimage;
	ofxCvContourFinder * contourFinder;
	
	NSMutableArray * surveyData;
	ofTrueTypeFont * font;

}
@property (readwrite, retain) NSMutableArray * surveyData;


-(float) aspect;
@end
