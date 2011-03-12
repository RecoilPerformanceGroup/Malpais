//
//  Ocean.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Ocean.h"
#import "Keystoner.h"


@implementation Ocean

-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"amplitude"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"alpha"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:70.0 minValue:1.0 maxValue:MAX_RESOLUTION] named:@"resolution"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:10.0] named:@"frequency"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0.0 maxValue:1.0] named:@"smootingRise"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.35 minValue:0.0 maxValue:1.0] named:@"smoothingFall"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.45 minValue:0.0 maxValue:1.0] named:@"smoothing"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"floorDepth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:-5.0 maxValue:5.0] named:@"drift"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:5.0] named:@"offset"];
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named: 
		 [NSString stringWithFormat:@"wave%iOn",i]
		 ];
		[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUM_VOICES] named:
		 [NSString stringWithFormat:@"wave%iChannel",i]
		 ];
		[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:
		 [NSString stringWithFormat:@"wave%iLength",i]
		 ];
	}
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"drag"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:-2.0 minValue:-2.0 maxValue:2.0 +[self aspect] ] named:@"dragToX"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"dragToY"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"dragWindowWidth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.01 minValue:0.0 maxValue:1.0] named:@"stiffness"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:YES] named:@"reset"];
	
	[self assignMidiChannel:9];
}

-(void) setup{
	
	voices = [NSMutableArray array];
	
	for (int i = 0; i < NUM_VOICES+1; i++) {
		waveForm[i] =  new MSA::Interpolator1D;
		waveForm[i]->reserve((int)roundf(PropF(@"resolution")));
		
		[voices addObject:[NSNull null]];
	}
	mouseParticle = new ofxParticle();
	mouseParticle->setActive(false);
	dragParticle = new ofxParticle();
	dragParticle->setActive(false);
	stillImg.setUseTexture(true);
	stillImg.loadImage([[[NSBundle mainBundle] pathForImageResource:@"floortest.jpg"] cString]);
	[[properties objectForKey:@"reset"] setBoolValue:YES];
	
	[self reset];
	
}

-(void) reset{
	ofxFbole::Settings s;
	s.width				= kFBOWidth;
	s.height			= kFBOHeight;
	s.useDepth			= false;
	s.numColorbuffers	= 1;
	fbo.setup(s);
	
	fbo.begin();{
		ofBackground(0,0,0);
	}fbo.end();
	
	ofPoint gravity(0, 0);
	if(physics){
		physics->removeAll();
		delete physics;
	}
	physics = new ofxPhysics2d(gravity);
	physics->checkBounds(false);
	physics->enableCollisions(true);
	physics->setNumIterations(10);
	
	wallParticles.clear();
	wallSprings.clear();
	springs.clear();
	
	bCreateParticles = false;
	mouseSpring = NULL;
	dragSpring = NULL;
	newParticle = NULL;
	dragOrigin = NULL;
	
	newParticleIncrement = 0;
	bCreateParticleString = false;
	beginParticleString = NULL;
	endParticleString = NULL;
	
	bSetup = false;
	grid = 6;
	if(_particles){
		delete _particles;
	}
	_particles = new ofxParticle*[grid];
	for(int x = 0 ; x < grid+1 ;x++)
	{
		_particles[x] = new ofxParticle[(int)(grid/[self aspect])+1];
	}
	[self makeSpringWidth:[self aspect]*400.0 height:1.0*400.0];
	
	[[properties objectForKey:@"reset"] setBoolValue:NO];
	[[properties objectForKey:@"drag"] setFloatValue:0.0];
	
	
	/*	for (int i = 0; i < wallSprings.size(); i++) {
	 physics->deleteConstraint(wallSprings[i]);
	 }
	 wallSprings.clear();
	 
	 for (int i = 0; i < wallParticles.size(); i++) {
	 physics->deleteParticle(wallParticles[i]);
	 }
	 wallParticles.clear();
	 */	
	int wallParticleResolution = 20;
	
	ofxParticle * lastParticle;
	lastParticle = NULL;
	
	for (int i = 0; i < wallParticleResolution; i++) {
		
		float particleRadius = 1.5;
		float particleMargin = (_particles[0][0].getRadius()/20.0);
		
		float wallX = (PropF(@"dragToX") < 0.5)?-((particleRadius+particleMargin)/wallParticleResolution):[self aspect]+((particleRadius+particleMargin)/wallParticleResolution);
		
		float rest;
		
		ofPoint wallParticlePos = ofPoint(wallX*400,400*(1.0/wallParticleResolution)*i);
		
		if (wallParticlePos.y/400.0 < PropF(@"dragToY")-(PropF(@"dragWindowWidth")*0.5) ||
			wallParticlePos.y/400.0 > PropF(@"dragToY")+(PropF(@"dragWindowWidth")*0.5)) {
			
			ofxParticle* p = new ofxParticle(wallParticlePos, particleRadius*400.0/wallParticleResolution);
			if (i==0 || i==wallParticleResolution-1) {
				p->setActive(false);
			} else {
				p->setActive(false);
			}
			
			p->setMass(100);
			wallParticles.push_back(p);
			physics->add(p);
			if(lastParticle){
				rest = p->distanceTo(lastParticle);
				ofxSpring* s = new ofxSpring(p, wallParticles[wallParticles.size()-2], rest*0.9, 1.0);
				wallSprings.push_back(s);
				physics->add(s);
			}
			
			lastParticle = p;
			
		}
		
	}
	
	
}

-(void) update:(NSDictionary *)drawingInformation{
	
	if (PropB(@"reset")) {
		
		[self reset];
		
	}
	
	for (int i=0; i<springs.size(); i++) {
		springs[i]->setStrength(PropF(@"stiffness"));
	}
	
	mouseParticle->set(mousex*400.0, mousey*400.0);
	
	if(mouseSpring && !bMousePressed){
		physics->deleteConstraint(mouseSpring);
		mouseSpring = NULL;
	}
	
	if(!dragSpring){
		float wallX = (PropF(@"dragToX") < 0.5)?0:[self aspect];
		ofPoint dragPoint = ofPoint(wallX*400, PropF(@"dragToY")*400);
		ofxParticle* particleToDrag = physics->getNearestParticle(dragPoint);
		if(particleToDrag){
			dragOrigin = new ofPoint(particleToDrag->x, particleToDrag->y);
			dragParticle->set(particleToDrag->x,particleToDrag->y);
			float rest = dragParticle->distanceTo(particleToDrag);
			dragSpring = new ofxSpring(dragParticle, particleToDrag, rest);
			physics->add(dragSpring);
		} 
	} else {
		dragParticle->set(dragOrigin->x + (((PropF(@"dragToX")*[self aspect]*400.0*3)-dragOrigin->x)*PropF(@"drag")),
						  dragOrigin->y + (((PropF(@"dragToY")*400.0)-dragOrigin->y)*PropF(@"drag"))
						  );
	}
	
	physics->update();
	
	int resolution = (int)roundf(PropF(@"resolution"));
	
	for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
		
		NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
		
		if (PropB(waveOnStr)) {
			
			NSString * waveChannelStr = [NSString stringWithFormat:@"wave%iChannel",iVoice];
			
			NSDictionary * currentVoice = [voices objectAtIndex:iVoice];
			
			NSDictionary * newVoice = [GetPlugin(Wave)getVoiceWithIndex:(int)roundf(PropF(waveChannelStr))
															  amplitude:1.0
															   preDrift:PropF(@"drift")
															  postDrift:0
														  smoothingRise:PropF(@"smoothingRise")
														  smoothingFall:PropF(@"smoothingFall")
															  smoothing:PropF(@"smoothing")
															  freqeuncy:PropF(@"frequency")
															 resolution:PropF(@"resolution")
																 random:0
																 offset:fmodf((iVoice/(NUM_VOICES+1.0))*PropF(@"offset"), 1.0)
												   withFormerDictionary:currentVoice
									   ];
			
			[voices replaceObjectAtIndex:iVoice withObject:newVoice];
			
			NSMutableArray * newWave = [newVoice objectForKey:@"waveLine"];

			if ([newWave count] > 0) {
				waveForm[iVoice]->clear();
				for (int i=0; i < [newWave count]; i++) {
					waveForm[iVoice]->push_back([[newWave objectAtIndex:i] floatValue]);
				}
				
			}
			
		}	
		
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	ofEnableAlphaBlending();
	
	ApplySurface(@"Floor");{
		
		fbo.begin();{
			
			ofBackground(0, 0, 0);
			ofSetColor(0, 0, 0, 255);
			
			glScaled(kFBOHeight, kFBOHeight, 0);
			
			ofRect(0, 0, 0.5, 1);
			
			glTranslated(0, 0.5/(NUM_VOICES+1), 0);
			
			for (int iVoice = 0; iVoice < NUM_VOICES+1; iVoice++) {
				
				NSString * waveOnStr = [NSString stringWithFormat:@"wave%iOn",iVoice];
				
				if (PropB(waveOnStr)) {
					float yPos = (1.0/(NUM_VOICES+1))*iVoice;
					ofxPoint2f * startP = new ofxPoint2f(0,yPos);
					ofxPoint2f * endP = new ofxPoint2f(0.5,yPos);
					[self drawWave:iVoice from:startP to:endP];
					delete startP;
					delete endP;
				}
			}
			
		}fbo.end();
		
		ofSetColor(255, 255, 255, 255);
		ofFill();
		ofRect(0, -PropF(@"floorDepth"), [self aspect], 1+PropF(@"floorDepth"));
		glPushMatrix();{
			glTranslated(0, -PropF(@"floorDepth"),0);
			glScaled(1.0/400.0, (1.0+PropF(@"floorDepth"))/400.0,0);
			[self drawCloth:&fbo.getTexture(0) showGrid:NO folds:0];
		}glPopMatrix();
		
		ofSetColor(0,0,0,255);
		ofFill();
		ofRect(-2.0, -PropF(@"floorDepth"), 4.0+[self aspect], -2.0); // top
		ofRect(-2.0, 1.0, 4.0+[self aspect], 2.0); // bottom
		ofRect(-2.0, -PropF(@"floorDepth"), 2.0, 4.0+PropF(@"floorDepth")); // left
		ofRect([self aspect], -PropF(@"floorDepth"), 4.0+[self aspect], 4.0+PropF(@"floorDepth")); // right
		
	} PopSurface();
	
}

-(void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end{
	
#pragma mark -
// TODO: draw folds as vertical springs that show when their perpendicular springs are shortened
#pragma mark -
	
	ofxVec2f v1 = ofxVec2f(end->x, end->y)-ofxVec2f(begin->x, begin->y);
	ofxVec2f v2 = ofxVec2f(0,1.0);
	
	float length = v1.length();
	
	glPushMatrix();{
		
		ofNoFill();
		ofSetLineWidth(4);
		
		ofSetColor(255, 255, 255, 255);
		
		glTranslated(begin->x,begin->y, 0);
		glRotated(-v1.angle(v2)+90, 0, 0, 1);
		
		int resolution = PropI(@"resolution");
		float amplitude = PropF(@"amplitude");
		
		NSString * waveLengthStr = [NSString stringWithFormat:@"wave%iLength",iVoice];

		int arrayLength = PropF(waveLengthStr) * resolution;
		
		glBegin(GL_QUAD_STRIP);
		ofxPoint2f lastPoint = ofxPoint2f(0,0);		
		for (int i = 0;i< arrayLength; i++) {
			float x = 1.0/resolution*i;
			
			if (i < resolution) {
				ofxPoint2f p = ofxPoint2f(x*length, waveForm[iVoice]->sampleAt(x)*amplitude);
				ofxVec2f v = p - lastPoint;
				ofxVec2f h = ofxVec2f(-v.y,v.x);
				h.normalize();
				h *= 0.003;
				glVertex2f((p+h).x, (p+h).y);
				glVertex2f((p-h).x, (p-h).y);				
				//				glVertex2f(x*length, offsets[iVoice][i]+((distortion[iVoice]->getData()[i]*weighLiveOrBuffer)+(waveForm[iVoice]->sampleAt(x)*(1.0-weighLiveOrBuffer)))*amplitude*f);
				lastPoint = p;
			}
		}
		glEnd();
		
	} glPopMatrix();
}

- (void) drawCloth:(ofTexture*)ref showGrid:(bool) showGrid folds:(float)folds{
	
	//glEnable(GL_DEPTH_TEST);
	
	ofSetColor(0, 0,0,255);
	for (int i = 0; i < grid; i++)
	{
		for (int j = 0; j < ((int)(grid/[self aspect])); j++)
		{
			float texCoorX = ref->getWidth()/grid*1.0f;
			float texCoorY = ref->getHeight()/grid*1.0f*[self aspect];
			ofxParticle *p1 = &_particles[i][j];
			ofxParticle *p2 = &_particles[i+1][j];
			ofxParticle *p3 = &_particles[i+1][j+1];
			ofxParticle *p4 = &_particles[i][j+1];
			
			glBegin(GL_QUADS);
			
			glTexCoord2f((texCoorX*i),(texCoorY*j));
			glVertex2f(  p1->x, p1->y);
			
			glTexCoord2f((texCoorX*(i+1)),(texCoorY*j));
			glVertex2f(  p2->x,p2->y);
			
			glTexCoord2f((texCoorX*(i+1)),(texCoorY*(j+1)));
			glVertex2f(  p3->x, p3->y);
			
			glTexCoord2f((texCoorX*(i)),(texCoorY*(j+1)));
			glVertex2f(  p4->x, p4->y);
			
			glEnd();
		}
	}
	
	
	ofSetColor(255,255,255,255);
	
	ref->bind();
	for (int i = 0; i < grid; i++)
	{
		for (int j = 0; j < ((int)(grid/[self aspect])); j++)
		{
			float texCoorX = ref->getWidth()/grid*1.0f;
			float texCoorY = ref->getHeight()/grid*1.0f*[self aspect];
			ofxParticle *p1 = &_particles[i][j];
			ofxParticle *p2 = &_particles[i+1][j];
			ofxParticle *p3 = &_particles[i+1][j+1];
			ofxParticle *p4 = &_particles[i][j+1];
			
			glBegin(GL_QUADS);
			
			glTexCoord2f((texCoorX*i),(texCoorY*j));
			glVertex2f(  p1->x, p1->y);
			
			glTexCoord2f((texCoorX*(i+1)),(texCoorY*j));
			glVertex2f(  p2->x,p2->y);
			
			glTexCoord2f((texCoorX*(i+1)),(texCoorY*(j+1)));
			glVertex2f(  p3->x, p3->y);
			
			glTexCoord2f((texCoorX*(i)),(texCoorY*(j+1)));
			glVertex2f(  p4->x, p4->y);
			
			glEnd();
		}
	}
	ref->unbind();
	//glDisable(GL_DEPTH_TEST);
	ofNoFill();
	
	if (showGrid)
	{
		if(physics){
			ofSetColor(240, 240, 240,64);		physics->renderParticles();
			ofSetColor(100, 100, 100,64);		physics->renderConstraints();			
		}
	}
	
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	ofBackground(0, 0, 0);
	ofEnableAlphaBlending();
	ofSetColor(255, 255, 255);
	
	if(mouseh != -1){
		ofEnableAlphaBlending();
		if(mouseh){
			ofNoFill();
		} else {
			ofFill();
		}
		ofSetColor(255, 255, 0,100);
		ofEllipse(mousex*200.0*(1.0/[self aspect]), mousey*400.0, 15, 15);
	}
	
	glPushMatrix();{
		
		glTranslated((0.5-[self aspect])*200, 0, 0);
		ofSetColor(255, 255, 255,127);
		[self drawCloth:&fbo.getTexture(0) showGrid:YES folds:0];
	} glPopMatrix();
	
	glPushMatrix();{
		
		glScaled(200*1.0/[self aspect], 400, 1);
		
		ofFill();
		
		ofSetColor(255, 0, 0,127);
		
		float wallX = (PropF(@"dragToX") < 0.5)?0:[self aspect];
		
		ofRect(wallX-0.01, 0, 0.02, PropF(@"dragToY")-(PropF(@"dragWindowWidth")*0.5));
		
		ofRect(wallX-0.01, PropF(@"dragToY")+(PropF(@"dragWindowWidth")*0.5), 0.02, 1.0);
		
		
	} glPopMatrix();
}

- (void)makeSpringWidth:(float) _width height:(float) _height{
	gridSizeX = _width/((grid)*1.0);
	gridSizeY = ((_height*[self aspect])/((grid)*1.0));
	
	//	gridSizeX = img.getWidth()/grid;
	//	gridSizeY = img.getHeight()/grid;
	gridPosX = 0;
	gridPosY =	0;
	strength = 0.1;
	
	pSize = gridSizeX *0.1;
	
	for(int x = 0 ; x <= grid  ;x++)
	{
		for(int y = 0 ; y <= (int)grid/[self aspect]  ;y++)
		{
			ofPoint particlePos = ofPoint(gridPosX+x*gridSizeX,gridPosY+y*gridSizeY);
			ofxParticle* p = new ofxParticle(particlePos, pSize);
			_particles[x][y] = *p;
			physics->add(&_particles[x][y]);
			
			
		}
	}
	for (int i = 0; i <= grid; i++)
    {
        for (int j = 0; j <= (int)grid/[self aspect]; j++)
        {
			
            if (j > 0)
            {
                ofxParticle *p1 = &_particles[i][j - 1];
                ofxParticle *p2 = &_particles[i][j];
				float rest = p1->distanceTo(p2);
				ofxSpring* s = new ofxSpring(p1, p2, rest, strength);
				physics->add(s);
				springs.push_back(s);
				if (i>0) {
					p1 = &_particles[i-1][j-1];
					p2 = &_particles[i][j];
					rest = p1->distanceTo(p2);
					ofxSpring* s = new ofxSpring(p1, p2, rest, strength);
					physics->add(s);
					springs.push_back(s);
				}
            }
            if (i > 0)
            {
                ofxParticle *p1 = &_particles[i - 1][j];
                ofxParticle *p2 = &_particles[i][j];
				
				float rest = p1->distanceTo(p2);
				ofxSpring* s = new ofxSpring(p1, p2, rest, strength);
				physics->add(s);
				springs.push_back(s);
				if (j>0) {
					p1 = &_particles[i-1][j];
					p2 = &_particles[i][j-1];
					rest = p1->distanceTo(p2);
					ofxSpring* s = new ofxSpring(p1, p2, rest, strength);
					physics->add(s);
					springs.push_back(s);
				}
            }
        }
    }
	
    for(int i = 0 ; i < (int)(grid/[self aspect]); i++)
    {
		// locking edges
		//_particles[(int)(i*[self aspect])][0].setActive(false);
		//		_particles[0][i].setActive(false);
		//		_particles[grid- 1][i].setActive(false);
		//		_particles[(int)(i*[self aspect])][(int)(grid/[self aspect]) - 1].setActive(false);
    }
	
}

-(void) controlMousePressed:(float)x y:(float)y button:(int)button{
	mousex = [self aspect]*x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
	
	bMousePressed = true;
	if(button == 0){
		ofPoint mousePoint = ofPoint(x-((0.5-[self aspect])*200), y);
		mouseParticle->set(x-((0.5-[self aspect])*200),y);
		ofxParticle* particleUnderMouse = physics->getNearestParticle(mousePoint);
		if(particleUnderMouse){
			float rest = mouseParticle->distanceTo(particleUnderMouse);
			cout << "dist: " << rest << endl;
			mouseSpring = new ofxSpring(mouseParticle, particleUnderMouse, rest);
			physics->add(mouseSpring);
		} 
	}
}

-(void) controlMouseDragged:(float)x y:(float)y button:(int)button{
	mousex = [self aspect] * x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseReleased:(float)x y:(float)y{
	mousex = [self aspect] * x / 200.0;
	mousey = y / 400.0;
	mouseh = -1;
	bMousePressed = false;
}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}



@end
