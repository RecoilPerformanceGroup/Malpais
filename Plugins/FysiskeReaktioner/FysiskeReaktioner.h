#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"


@interface FysiskeReaktioner : ofPlugin {
	IBOutlet NSButton * debugButton;
		IBOutlet NSButton * debugCamperButton;
}

-(ofxVec2f) floorCoordinate:(int)i;
-(ofxPoint2f) mapToWall:(ofxPoint3f)pIn;
@end
