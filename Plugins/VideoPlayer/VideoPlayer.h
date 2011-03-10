#pragma once

#include "Plugin.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#import "BSender.h"
//#import "BReceiver.h"
#import <QTKit/QTKit.h>

//#import "ArduinoController.h"

@class QTMovie;
#define NUMVIDEOS 4

@interface VideoPlayer : ofPlugin {
	QTMovie     		*movie[NUMVIDEOS];
	QTVisualContextRef	textureContext[NUMVIDEOS];
	CVOpenGLTextureRef  currentFrame[NUMVIDEOS];
	
	int lastFramesVideo;
	BOOL forceDrawNextFrame;
//	ArduinoController * arduino;
	NSMutableArray * loadedFiles;
	IBOutlet NSArrayController * loadedFilesController;
	BOOL cancelReboot;
	
	IBOutlet NSPopUpButton * videoSelector;
	IBOutlet NSPopUpButton * chapterSelector;

}

@property (readwrite, retain) NSMutableArray * loadedFiles;
-(IBAction) restart:(id)sender;
-(IBAction) sleepComputer:(id)sender;
-(IBAction) restartComputer:(id)sender;
@end
