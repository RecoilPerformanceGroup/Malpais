#include "Plugin.h"
#import <AudioToolbox/AudioToolbox.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "CAAudioUnit.h"

@interface WaveObject : NSObject {
	float y;
	
	ExtAudioFileRef audioFile;
	float *audioBuffer;
	
	UInt64 numFrames;
	int i;
	
	float avgMin, avgMax;
	
	vector<float> simplifiedCurve;
}

@property (readonly) float y;
@property (readonly) float avgMin;
@property (readonly) float avgMax;
@property (readonly) vector<float>  simplifiedCurve;

-(void) updateWithSpeed:(float)speed;
-(void) loadAudio:(NSString*)name;
-(float *) getWaveData;

@end
