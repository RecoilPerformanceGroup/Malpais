#include "Plugin.h"
#define NUMIMAGES 3

@interface SceneX : ofPlugin {
	ofImage * images[NUMIMAGES];
	
	float backlinesCache[4];
}

-(float) getBackline:(int)n;

@end
