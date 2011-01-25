#pragma once

#include "Plugin.h"

#import "WaveObject.h"
//#include "AudioDeviceList.h"


@interface Wave : ofPlugin {
	NSMutableArray * waves;
	
	IBOutlet NSPopUpButton *		mInputDevices;
	//AudioDeviceList *				mInputDeviceList;
	//AudioDeviceID					inputDevice;
	

}
-(IBAction) startWave:(id)sender;
//- (IBAction)inputDeviceSelected:(id)sender;

@end
