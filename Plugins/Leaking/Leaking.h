#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"
#include "ofxOpenCv.h"

#define IMGWIDTH 300.0
#define IMGHEIGHT 600.0
#define NUMIMAGES 5

@interface Leaking : ofPlugin {
	ofxCvFloatImage * images[NUMIMAGES];
	ofxCvContourFinder * contourFinder[NUMIMAGES];

	
	ofxCvFloatImage * tmpImage;
	
	float mousex,mousey,mouseh;
	
	vector<CvPoint> storedPoints;

	bool clear;
	
	bool imageSelected;
	int curImage;
	int timeoutCounter[NUMIMAGES];
	
	float blurSpeed[NUMIMAGES];
	float blurCounter[NUMIMAGES];
	

}

-(float) percentage:(int)image;
@end
