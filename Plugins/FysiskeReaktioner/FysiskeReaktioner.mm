//
//  FysiskeReaktioner.mm
//  malpais
//
//  Created by Jonas Jongejan on 28/01/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#import "FysiskeReaktioner.h"
#import "Kinect.h"
#import "Keystoner.h"

@implementation FysiskeReaktioner

-(void) setup{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"camperWheelHeight"];
}

-(void) update:(NSDictionary *)drawingInformation{
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	//Debug
	if([debugButton state]){
		ofSetColor(255, 255, 0);
		
		ofxPoint3f lfoot, rfoot;
		if([GetPlugin(Kinect) getUserGenerator]->getTrackedUsers().size()){
			ofxTrackedUser * user = [GetPlugin(Kinect) getUserGenerator]->getTrackedUsers()[0];
			lfoot = [self mapToWall:user->left_lower_arm.worldEnd];
			rfoot = [self mapToWall:user->right_lower_arm.worldEnd];
		}
		
		
		ApplySurface(@"Wall");{
			
			ofSetLineWidth(1);
			ofFill();
			ofSetColor(255, 255, 0);
			ofCircle(lfoot.x, lfoot.y, 10.0/640);
			
			ofSetLineWidth(1);
			ofFill();
			ofSetColor(255, 255, 0);
			ofCircle(rfoot.x, rfoot.y, 10.0/640);
			
		}PopSurface();
		
		
		ApplySurface(@"Floor");{
			ofSetLineWidth(1);
			ofFill();
			ofSetColor(255, 255, 0);
			ofxPoint2f p = [self floorCoordinate:0];
			ofCircle(p.x, p.y, 4.0/640);			
			p = [self floorCoordinate:1];
			ofCircle(p.x, p.y, 4.0/640);			
			
		}PopSurface();
		
	}
	if([debugCamperButton state]){
		
		ApplySurface(@"Wall");{
			ofFill();
			ofSetColor(255, 0, 0);
			ofRect(0, 0, Aspect(@"Wall",0), 1);
			ofSetColor(255, 255, 255);
			ofRect(0, 1, Aspect(@"Wall",0), PropF(@"camperWheelHeight"));
		}PopSurface();
	}
}

-(ofxPoint2f) mapToWall:(ofxPoint3f)pIn{
	ofxPoint3f p = [GetPlugin(Kinect) convertWorldToProjection:pIn];
	//P er nu i floor space.
	
	//Flyt punktet til foden
	p.x -= [self floorCoordinate:0].x;
	p.z -= [self floorCoordinate:0].y;
	
	//Roter punktet 
	float angle = ([self floorCoordinate:1] - [self floorCoordinate:0]).angle(ofxVec2f(1,0));
	ofxVec2f _v = ofxVec2f(p.x,p.z);
	_v.rotate(-angle);
	
	p.x = _v.x;
	p.z = _v.y;
	
	//Skaler målene
	float scale = 1.0/([self floorCoordinate:1] - [self floorCoordinate:0]).length();
	p *= scale;
	
	return p;
	
}

-(ofxVec2f) floorCoordinate:(int)i{
	KeystoneSurface * floor = ([GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0]);
	KeystoneSurface * wall = ([GetPlugin(Keystoner) getSurface:@"Wall" viewNumber:0 projectorNumber:0]);	
	
	ofxPoint2f p[2];
	p[0] = [wall convertToProjection:ofxPoint2f(0,1+PropF(@"camperWheelHeight"))];
	p[1] = [wall convertToProjection:ofxPoint2f([[wall aspect] floatValue],1+PropF(@"camperWheelHeight"))];
	
	for(int j=0;j<2;j++){
		p[j] = [floor convertFromProjection:p[j]];
	}
	
	return p[i];
}

/*
 -(ofxVec2f) normal:(ofxPoint2f)p{
 KeystoneSurface * surface =  [GetPlugin(Keystoner) getSurface:@"Wall" viewNumber:0 projectorNumber:0];
 ofxVec2f normal = PropF(@"yScale") * ([surface convertToProjection:ofPoint(0,0)] - [surface convertToProjection:ofPoint(0,1)]).normalized();
 return normal;
 }
 */
@end
