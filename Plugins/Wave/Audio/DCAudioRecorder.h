#ifndef _DCAudioFileRecorder_H_
#define _DCAudioFileRecorder_H_

#include <Carbon/Carbon.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>

#include "CARingBuffer.h"

class DCAudioRecorder 
{
public:
	DCAudioRecorder();
	virtual ~DCAudioRecorder();

	AudioBufferList	*AllocateAudioBufferList(UInt32 numChannels, UInt32 size);
	void	DestroyAudioBufferList(AudioBufferList* list);
	OSStatus	ConfigureOutputFile(const FSRef inParentDirectory, const CFStringRef inFileName, AudioStreamBasicDescription *inASBD);
	OSStatus	ConfigureAU();
//	OSStatus	Configure(const FSRef inParentDirectory, const CFStringRef inFileName, AudioStreamBasicDescription *inASBD);
	OSStatus	Configure(int bufferSize);
	OSStatus	Start();
	OSStatus	Stop();

	AudioBufferList	*fAudioBuffer;
	float *audioBuffer;
	int bufferSize;
	int index;
	AudioUnit	fAudioUnit;
	ExtAudioFileRef fOutputAudioFile;
	CARingBuffer *mBuffer;

	
protected:
	static OSStatus AudioInputProc(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);

	AudioDeviceID	fInputDeviceID;
	UInt32	fAudioChannels, fAudioSamples;
	AudioStreamBasicDescription	fOutputFormat, fDeviceFormat;
	FSRef fOutputDirectory;

};

#endif // _DCAudioFileRecorder_H_