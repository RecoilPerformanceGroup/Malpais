//
//  Wave.h
//  malpais
//
//  Created by ole kristensen on 11/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#include "Plugin.h"

#define NUM_VOICES 8
#define NUM_BANDS 7
#define MAX_RESOLUTION 128
#define MIDI_CHANNEL 1


@interface Wave : ofPlugin {

	NSMutableArray * voiceWaveForms;

}

@end
