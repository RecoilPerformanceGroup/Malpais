//
//  Ocean.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Ocean.h"
#import "Keystoner.h"

#pragma mark TODO add ofxFBO

@implementation Ocean


-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"drag"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:-1.0 minValue:-1.0 maxValue:2.0] named:@"dragToX"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"dragToY"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"dragWindowWidth"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:YES] named:@"reset"];
}

-(void) setup{
	mouseParticle = new ofxParticle();
	mouseParticle->setActive(false);
	dragParticle = new ofxParticle();
	dragParticle->setActive(false);
	stillImg.setUseTexture(true);
	stillImg.loadImage([[[NSBundle mainBundle] pathForImageResource:@"floortest.jpg"] cString]);
	[[properties objectForKey:@"reset"] setBoolValue:YES];

}

-(void) update:(NSDictionary *)drawingInformation{
	
	if (PropB(@"reset")) {

		ofPoint gravity(0, 0);
		if(physics){
			physics->deleteAll();
		}
		physics = new ofxPhysics2d(gravity);
		physics->checkBounds(false);
		physics->enableCollisions(true);
		physics->setNumIterations(10);
		
		wallParticles.clear();
		
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
		grid = 15;
		if(_particles){
			delete _particles;
		}
		_particles = new ofxParticle*[grid];
		for(int x = 0 ; x < grid ;x++)
		{
			_particles[x] = new ofxParticle[(int)(grid/[self aspect])];
		}
		[self makeSpringWidth:[self aspect]*400.0 height:1.0*400.0];

		[[properties objectForKey:@"reset"] setBoolValue:NO];
		[[properties objectForKey:@"drag"] setFloatValue:0.0];
		
	}
	
	mouseParticle->set(mousex*400.0, mousey*400.0);
	
	for(int i=0; i<particles.size(); i++){
		if(particles[i]->y > 400 + particles[i]->getRadius()){
			while(physics->getConstraintWithParticle(particles[i]) != NULL){
				physics->deleteConstraintsWithParticle(particles[i]);
			}
			physics->deleteParticle(particles[i]);
			particles.erase(particles.begin()+i);
		}
	}
	
	if(mouseSpring && !bMousePressed){
		physics->deleteConstraint(mouseSpring);
		mouseSpring = NULL;
	}
	
	for (int i = 0; i < wallParticles.size(); i++) {
		physics->deleteParticle(wallParticles[i]);
	}
	wallParticles.clear();
	
	int wallParticleResolution = 20;
	
	for (int i = 0; i < wallParticleResolution; i++) {
		
		float wallX = (PropF(@"dragToX") < 0.5)?-(1.2/wallParticleResolution):[self aspect]+(1.2/wallParticleResolution);
		
		ofPoint wallParticlePos = ofPoint(wallX*400,400*(1.0/wallParticleResolution)*i);
		
		if (wallParticlePos.y/400.0 < PropF(@"dragToY")-(PropF(@"dragWindowWidth")*0.5) ||
			wallParticlePos.y/400.0 > PropF(@"dragToY")+(PropF(@"dragWindowWidth")*0.5)) {

			ofxParticle* p = new ofxParticle(wallParticlePos, 400.0/wallParticleResolution);
			p->setActive(false);
			p->setMass(200);
			wallParticles.push_back(p);
			physics->add(p);
		}
		
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
		dragParticle->set(ofPoint(
								  dragOrigin->x + (((PropF(@"dragToX")*[self aspect]*400.0*3)-dragOrigin->x)*PropF(@"drag")),
								  dragOrigin->y + (((PropF(@"dragToY")*400.0)-dragOrigin->y)*PropF(@"drag"))
						  ));
	}

	
	physics->update();
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	ApplySurface(@"Floor");{
		
		ofSetColor(255, 255, 255, 255);
		
		glScaled(1.0/400.0, 1.0/400.0,0);
		[self drawCloth:&stillImg showGrid:NO];
		
	} PopSurface();
	
}

- (void) drawCloth:(ofImage*)img showGrid:(bool) showGrid{
	ofTexture *ref;
	ref = &img->getTextureReference();
	
	glEnable(GL_DEPTH_TEST);
	ref->bind();
	for (int i = 0; i < grid-1; i++)
	{
		for (int j = 0; j < ((int)(grid/[self aspect]))-1; j++)
		{
			float texCoorX = img->getWidth()/grid*1.0f;
			float texCoorY = img->getHeight()/grid*1.0f*[self aspect];
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
	glDisable(GL_DEPTH_TEST);
	ofNoFill();
	
	if (showGrid)
	{
		ofSetColor(240, 240, 240,64);		physics->renderParticles();
		ofSetColor(100, 100, 100,64);		physics->renderConstraints();
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
	
	
	ofSetColor(255, 255, 255,127);

		[self drawCloth:&stillImg showGrid:YES];

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
	gridSizeX = _width/((grid-1)*1.0);
	gridSizeY = (_height/((grid-1)*1.0))*[self aspect];
	
	//	gridSizeX = img.getWidth()/grid;
	//	gridSizeY = img.getHeight()/grid;
	gridPosX = 0;
	gridPosY =	0;
	strength = 0.1;
	
	pSize = gridSizeX *0.1;
	
	for(int x = 0 ; x < grid  ;x++)
	{
		for(int y = 0 ; y < (int)grid/[self aspect]  ;y++)
		{
			ofPoint particlePos = ofPoint(gridPosX+x*gridSizeX,gridPosY+y*gridSizeY);
			ofxParticle* p = new ofxParticle(particlePos, pSize);
			_particles[x][y] = *p;
			physics->add(&_particles[x][y]);
			
			
		}
	}
	for (int i = 0; i < grid; i++)
    {
        for (int j = 0; j < (int)grid/[self aspect]; j++)
        {
			
            if (j > 0)
            {
                ofxParticle *p1 = &_particles[i][j - 1];
                ofxParticle *p2 = &_particles[i][j];
				float rest = p1->distanceTo(p2);
				ofxSpring* s = new ofxSpring(p1, p2, gridSizeY, strength);
				physics->add(s);
            }
            if (i > 0)
            {
                ofxParticle *p1 = &_particles[i - 1][j];
                ofxParticle *p2 = &_particles[i][j];
				
				float rest = p1->distanceTo(p2);
				ofxSpring* s = new ofxSpring(p1, p2, gridSizeX, strength);
				physics->add(s);
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
	mousex = [self aspect] * x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
	
	cout << "controlMousePressed: " << x << "," << y << endl;
	
	bMousePressed = true;
	if(button == 0){
		ofPoint mousePoint = ofPoint(x, y);
		mouseParticle->set(x,y);
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
