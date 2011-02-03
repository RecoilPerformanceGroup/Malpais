#pragma once

#include "Plugin.h"
#include "ofxOpenNI.h"
#include "ofxOpenCv.h"
#include "Filter.h"

#define NUM_SEGMENTS 6

struct Dancer {
	int userId;
	int state;
};


@interface PersistentBlob : NSObject
{
@public
	long unsigned int pid;
	ofxPoint2f * centroid;
	ofxPoint2f * lastcentroid;
	ofxVec2f   * centroidV;
	
	ofxPoint3f * centroidFiltered;

	Filter * centroidFilter[3];
	
	int timeoutCounter;
	NSMutableArray * blobs;
	long age;
	
}
@property (assign) NSMutableArray * blobs;

-(ofxPoint2f) getLowestPoint;
-(ofxPoint3f) centroidFiltered;
-(void) dealloc;

@end


@interface Blob : NSObject
{
	int cameraId;
	ofxCvBlob * blob;
	ofxCvBlob * originalblob;
	ofxCvBlob * floorblob;
	ofxPoint2f * low;
	int segment;
	
	int avgDepth;
@public
	CvSeq * cvSeq; 
}
@property (readwrite) int cameraId;
@property (readonly) ofxCvBlob * originalblob;
@property (readonly) ofxCvBlob * floorblob;
@property (readwrite) int segment;
@property (readwrite) int avgDepth;

-(void) normalize:(int)w height:(int)h;
-(void) dealloc;

-(id)initWithBlob:(ofxCvBlob*)_blob;
-(id)initWithMouse:(ofPoint*)point;

-(vector <ofPoint>)pts;
-(int)nPts;
-(ofPoint)centroid;
-(float) area;
-(float)length;
-(ofRectangle) boundingRect;
-(BOOL) hole;

-(ofxPoint2f) getLowestPoint;



@end




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
	
	IBOutlet NSTabView * openglTabView;
	
	
	
	Dancer dancers[3];
	
	BOOL kinectConnected;
	

	ofxCvGrayscaleImage *	grayImage[NUM_SEGMENTS];
	ofxCvGrayscaleImage * threadGrayImage[NUM_SEGMENTS];

	XnDepthPixel* threadedPixels;
	XnDepthPixel* threadedPixelsSorted;

	BOOL threadUpdateContour;
	
	ofxCvContourFinder 	* contourFinder;
	NSMutableArray * blobs;
	NSMutableArray * threadBlobs;
	NSMutableArray * persistentBlobs;

	
	NSThread * thread;
	pthread_mutex_t mutex;
	pthread_mutex_t drawingMutex;
		
	unsigned char pixelBuffer[640*480];
	unsigned char pixelBufferTmp[640*480];
	
	int distanceNear[NUM_SEGMENTS];
	int distanceFar[NUM_SEGMENTS];
	
	int threadHeatMap[1000];
	ofxPoint3f threadWorldPos[640*480];
	
	long unsigned int pidCounter;

}

@property (copy, readwrite) NSMutableArray * blobs;
@property (readonly) NSMutableArray * persistentBlobs;

-(ofxPoint2f) point2:(int)point;
-(ofxPoint3f) point3:(int)point;
-(ofxPoint2f) projPoint:(int)point;

-(void) setPoint3:(int) point coord:(ofxPoint3f)coord;
-(void) setPoint2:(int) point coord:(ofxPoint2f)coord;
-(void) setProjPoint:(int) point coord:(ofxPoint2f)coord;

-(ofxPoint3f) convertKinectToWorld:(ofxPoint3f)p;
-(ofxPoint3f) convertWorldToProjection:(ofxPoint3f) p;
-(ofxPoint3f) convertWorldToFloor:(ofxPoint3f) p;


-(void) calculateMatrix;

-(float) floorAspect;

-(IBAction) storeCalibration:(id)sender;
-(IBAction) setPriority:(id)sender;

-(ofxTrackedUser*) getDancer:(int)d;
-(ofxUserGenerator*) getUserGenerator;

-(void) performBlobTracking:(id)param;
@end
