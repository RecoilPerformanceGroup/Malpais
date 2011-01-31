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
	
}

-(void) update:(NSDictionary *)drawingInformation{
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	//Debug
	if([debugButton state]){
		ofSetColor(255, 255, 0);

		ofxPoint3f lfoot, rfoot;
		if([GetPlugin(Kinect) getDancer:0] != nil){
			ofxTrackedUser * user = [GetPlugin(Kinect) getDancer:0];
			lfoot = [GetPlugin(Kinect) convertWorldToProjection:user->left_lower_leg.worldEnd];
			rfoot = [GetPlugin(Kinect) convertWorldToProjection:user->right_lower_leg.worldEnd];
			cout<<"Found"<<endl;
		}
		
		ofSetLineWidth(1);
		ofFill();
		ofSetColor(255, 255, 0);
		ofCircle(lfoot.x, lfoot.y, 10.0/640);
		
	}
}
/*
-(ofxVec2f) normal:(ofxPoint2f)p{
	KeystoneSurface * surface =  [GetPlugin(Keystoner) getSurface:@"Wall" viewNumber:0 projectorNumber:0];
	ofxVec2f normal = PropF(@"yScale") * ([surface convertToProjection:ofPoint(0,0)] - [surface convertToProjection:ofPoint(0,1)]).normalized();
	return normal;
}
*/
@end
