#pragma once

#include "Plugin.h"
#include "MSAInterpolator.h"
#include "ofxVec2f.h"
#include "Wave.h"
#include "ofxPhysics2d.h"

@interface Umbilical : ofPlugin {
	
	float mousex,mousey,mouseh;

	ofxPhysics2d*physics;
	vector<ofxParticle*>umbilicalParticles;
	vector<ofxSpring*>umbilicalSprings;
		
	MSA::Interpolator1D		* distortion[NUM_VOICES+1];
	MSA::Interpolator1D		* waveForm[NUM_VOICES+1];

	vector<float> offsets[NUM_VOICES +1];
	
	NSMutableArray * wave;
	
	NSMutableArray * waves;
	
	bool reversed;
	
	ofxVec2f startPos;
	ofxVec2f endPos;
	
	float waveX[NUM_VOICES+1];
	
}

-(float) aspect;


@end
