#pragma once

#include "Plugin.h"
#include "ofxOpenNI.h"

struct Dancer {
	int userId;
	int state;
};

@interface Kinect : ofPlugin {
	ofxOpenNIContext  context;
	ofxDepthGenerator  depth;
	ofxUserGenerator  users;
	
	int draggedPoint;
	ofxMatrix4x4 rotationMatrix;
	float scale;

	BOOL stop;
	
	IBOutlet NSButton * drawCalibration;
	
	IBOutlet NSButton * storeA;
	IBOutlet NSSegmentedControl * priorityA;
	IBOutlet NSTextField * labelA;

	IBOutlet NSButton * storeB;
	IBOutlet NSSegmentedControl * priorityB;
	IBOutlet NSTextField * labelB;

	IBOutlet NSButton * storeC;
	IBOutlet NSSegmentedControl * priorityC;
	IBOutlet NSTextField * labelC;
	
	Dancer dancers[3];
	
	BOOL kinectConnected;
}

-(ofxPoint2f) point2:(int)point;
-(ofxPoint3f) point3:(int)point;
-(ofxPoint2f) projPoint:(int)point;

-(void) setPoint3:(int) point coord:(ofxPoint3f)coord;
-(void) setPoint2:(int) point coord:(ofxPoint2f)coord;
-(void) setProjPoint:(int) point coord:(ofxPoint2f)coord;

-(ofxPoint3f) convertWorldToProjection:(ofxPoint3f) p;
-(ofxPoint3f) convertWorldToFloor:(ofxPoint3f) p;

-(void) calculateMatrix;

-(float) floorAspect;

-(IBAction) storeCalibration:(id)sender;
-(IBAction) setPriority:(id)sender;

-(ofxTrackedUser*) getDancer:(int)d;
@end
