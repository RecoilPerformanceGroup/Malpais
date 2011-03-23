#pragma once

#include "Plugin.h"
#include "MSAInterpolator.h"
#include "ofxVec2f.h"
#include "Wave.h"
#include "ofxPhysics2d.h"
#import "SceneX.h"


#define SINGELMODE

@interface Umbilical : ofPlugin {
	
	float mousex,mousey,mouseh;

	MSA::Interpolator1D		* distortion[NUM_VOICES+1];
	MSA::Interpolator1D		* waveForm[NUM_VOICES+1];
	
	vector<float> offsets[NUM_VOICES +1];

	WaveArray * wave;
	
	NSMutableArray * voices;
	NSMutableArray * waveForms;

	bool reversed;
	
	ofxVec2f startPos;
	ofxVec2f endPos;
	ofxVec2f leftPoint;
	ofxVec2f rightPoint;
	
	float waveX[NUM_VOICES+1];
	
	ofxPhysics2d*physics;
	ofxParticle ** particles;

	vector<ofxSpring*>springs;
	vector<ofxSpring*>secondarySprings;
	vector<ofxSpring*>glueSprings;
	vector<ofxSpring*>glueEndSprings;
	
	vector<float> moveForce;
	int particlesLength;
	int numStrings;
	
	MSA::Interpolator2D ** springInterpolator;
	ofImage gradient;
	
	SceneX * sceneX;
	float aspectCache;
	
	float actualPushForce;
	
	float blobLeftOffset;
	float blobRightOffset;
}

-(float) aspect;


@end
