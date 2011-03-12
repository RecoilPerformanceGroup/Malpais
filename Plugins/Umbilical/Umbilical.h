#pragma once

#include "Plugin.h"
#include "MSAInterpolator.h"
#include "ofxVec2f.h"
#include "Wave.h"
#include "ofxPhysics2d.h"

//#define SINGELMODE

@interface Umbilical : ofPlugin {
	
	float mousex,mousey,mouseh;

	MSA::Interpolator1D		* distortion[NUM_VOICES+1];
	MSA::Interpolator1D		* waveForm[NUM_VOICES+1];
	


	vector<float> offsets[NUM_VOICES +1];

	NSMutableArray * wave;
	
	NSMutableArray * voices;
	NSMutableArray * waveForms;

	bool reversed;
	
	ofxVec2f startPos;
	ofxVec2f endPos;
	
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
}

-(float) aspect;


@end
