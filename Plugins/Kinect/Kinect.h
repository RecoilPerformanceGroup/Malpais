#pragma once

#include "Plugin.h"
#include "ofxOpenNI.h"

@interface Kinect : ofPlugin {
	ofxOpenNIContext  context;
	ofxDepthGenerator  depth;
	ofxUserGenerator  users;
	
	int draggedPoint;
	ofxMatrix4x4 rotationMatrix;
	float scale;

	BOOL stop;
}

-(ofxPoint2f) point2:(int)point;
-(ofxPoint3f) point3:(int)point;
-(ofxPoint2f) projPoint:(int)point;

-(void) setPoint3:(int) point coord:(ofxPoint3f)coord;
-(void) setPoint2:(int) point coord:(ofxPoint2f)coord;
-(void) setProjPoint:(int) point coord:(ofxPoint2f)coord;

-(ofxPoint3f) convertWorldToProjection:(ofxPoint3f) p;
-(void) calculateMatrix;

-(float) floorAspect;
@end
