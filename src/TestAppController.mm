#import "TestAppController.h"
#include "PluginIncludes.h"
#include "ofAppCocoaWindow.h"

extern ofAppBaseWindow * window;

@implementation TestAppController

-(void) setupApp{
	[pluginManagerController setNumberOutputViews:1];	
}


-(void) setupPlugins{
	NSLog(@"Setup plugins");
	
	[pluginManagerController addHeader:@"Input"];	
	[pluginManagerController addPlugin:[[Kinect alloc] init]];
//	[pluginManagerController addPlugin:[[Tracking alloc] init]];
	[pluginManagerController addPlugin:[[Midi alloc] init]];
	[pluginManagerController addPlugin:[[Wave alloc] init]];

	[pluginManagerController addHeader:@"Core Plugins"];
	[pluginManagerController addPlugin:[[Keystoner alloc] initWithSurfaces:[NSArray arrayWithObjects:@"Floor", @"Wall", nil]]];

	[pluginManagerController addHeader:@"Scener"];
	//[pluginManagerController addPlugin:[[Leaking alloc] init]];
	[pluginManagerController addPlugin:[[TrackingElements alloc] init]];
//	[pluginManagerController addPlugin:[[Umbilical alloc] init]];
	[pluginManagerController addPlugin:[[VideoPlayer alloc] init]];
	[pluginManagerController addPlugin:[[Ocean alloc] init]];
	[pluginManagerController addPlugin:[[Beach alloc] init]];
	[pluginManagerController addPlugin:[[Voice alloc] init]];
	[pluginManagerController addPlugin:[[Statestik alloc] init]];

	[pluginManagerController addPlugin:[[SceneX alloc] init]];
}

-(void) awakeFromNib {
	cocoaWindow = window;	
	((ofAppCocoaWindow*)cocoaWindow)->windowController = self;
	
	ofSetBackgroundAuto(false);
}


-(void) showMainWindow{
}

@end
