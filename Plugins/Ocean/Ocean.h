//
//  Ocean.h
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#pragma once
#include "Plugin.h"
#include "ofxPhysics2d.h"
#include "ofxFbole.h"
#include "MSAInterpolator.h"
#include "Wave.h"
#include "ofxPoint2f.h"

#define kFBOWidth			500
#define kFBOHeight			1000

@interface Ocean : ofPlugin {

	ofxPhysics2d*physics;
	ofxParticle* mouseParticle;
	ofxSpring*mouseSpring;
	ofxParticle* dragParticle;
	ofxSpring*dragSpring;
	ofPoint * dragOrigin;
	ofxParticle* newParticle;
	bool bCreateParticles;
	float newParticleIncrement;
	
	vector<ofxParticle*>wallParticles;

	ofxFbole fbo;
	
	bool bCreateParticleString;
	ofxParticle* beginParticleString;
	ofxParticle* endParticleString;

	ofxParticle **_particles;
	int grid;
	float gridSizeX,gridSizeY,gridPosX,gridPosY,pSize;
	float strength;
	
	bool bSetup;
	ofImage stillImg;
	bool bRender;
	
	ofxParticle** tuioParticle;
	ofxSpring** tuioSpring;
	int max_tuio_constraints;
	bool bMousePressed;
	
	MSA::Interpolator1D		* waveForm[NUM_VOICES+1];
	
	float mousex, mousey, mouseh;
	
	NSMutableArray * wave;
	
}

- (void)makeSpringWidth:(float) _width height:(float) _height;
- (float) aspect;
- (void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end;



@end
