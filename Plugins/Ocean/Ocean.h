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

	
	bool bCreateParticleString;
	ofxParticle* beginParticleString;
	ofxParticle* endParticleString;
	vector<ofxParticle*>particles;
	
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
	
	float mousex, mousey, mouseh;
	
}

- (void)createParticleStringFrom:(ofxParticle*)begin to:(ofxParticle*) end withNumParticles: (int) numParticles;
- (void)makeSpringWidth:(float) _width height:(float) _height;
- (float) aspect;


@end
