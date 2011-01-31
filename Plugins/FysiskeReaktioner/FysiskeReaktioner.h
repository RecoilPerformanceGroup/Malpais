#pragma once

#include "Plugin.h"
#include "ofxVectorMath.h"


@interface FysiskeReaktioner : ofPlugin {
	IBOutlet NSButton * debugButton;
}

-(ofxVec2f) normal:(ofxPoint2f)p;

@end
