//
//  FysiskeReaktioner.mm
//  malpais
//
//  Created by Jonas Jongejan on 28/01/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#import "TrackingElements.h"
#import "Kinect.h"
#import "Keystoner.h"

@implementation TrackingElements

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"ruler1"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"ruler2"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"ruler3"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1000] named:@"handscale"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:2 minValue:0.1 maxValue:3] named:@"rulerScale"];	
	
}

-(void) setup{
	font = new ofTrueTypeFont();
	font->loadFont("/Users/malpais/Udvikling/of_preRelease_v0062_osxSL_FAT/apps/recoil/Malpais/bin/data/LucidaGrande.ttc", 20, true, true, true);
}

-(void) update:(NSDictionary *)drawingInformation{
	
}

-(void) drawRulerBetween:(ofxPoint3f)p1_3 andP2:(ofxPoint3f)p2_3{
	ofxPoint2f p1 = ofxPoint2f(p1_3.x, p1_3.z);
	ofxPoint2f p2 = ofxPoint2f(p2_3.x, p2_3.z);
	ofSetColor(255, 255, 255);
	ofLine(p1.x, p1.y, p2.x, p2.y);
	ofxPoint2f v = p1 - p2;
	ofxPoint2f center = p2 + v*0.5;
	
	glPushMatrix();{
		glTranslated(p2.x, p2.y, 0);
		glRotated(-v.angle(ofxVec2f(1,0)), 0, 0, 1);
		glTranslated(v.length()*0.5,0,0);
		
		float textScale = 0.001*PropF(@"rulerScale");
		string s = ofToString(v.length()*9.6, 1)+"m";
		float width = font->stringWidth(s)*textScale;
		float height = font->stringHeight(s)*textScale;
		
		ofSetColor(0, 0, 0);
		ofRect(-1.1*width/2.0, -0.03, 1.1*width, 0.06);	
		ofSetColor(255, 255, 255);
		glScaled(textScale, textScale, 1);
		font->drawString(s, -1.0/textScale*width/2.0, +1.0/textScale*height*0.3);
	}glPopMatrix();
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	if(PropF(@"ruler1") > 0){
		//Find de to ældste blobs
		NSMutableArray * pblobs = [GetPlugin(Kinect) persistentBlobs];
		
		if([pblobs count] >= 2){
			PersistentBlob * oldest = nil;
			PersistentBlob * secOldest = nil;
			for(PersistentBlob * b in pblobs){
				if(oldest == nil || b->age > oldest->age)
					oldest = b;
			}
			for(PersistentBlob * b in pblobs){
				if((secOldest == nil || b->age > oldest->age) && b != oldest)
					secOldest = b;
			}
			
			if(oldest != nil && secOldest != nil){
				ApplySurface(@"Floor");

				[self drawRulerBetween:[oldest centroidFiltered] andP2:[secOldest centroidFiltered]];
				PopSurface();

			}
			
		}
	}
	if(PropF(@"ruler2") > 0){
		
		ofxPoint3f lfoot, rfoot, lhand, rhand;
		ofxUserGenerator * users = [GetPlugin(Kinect) getUserGenerator];
		if(users->getTrackedUsers().size() > 0){
			ofxTrackedUser * user = users->getTrackedUser(0);
			lfoot = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_leg.worldEnd];
			rfoot = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_leg.worldEnd];
			lhand = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_arm.worldEnd];
			rhand = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_arm.worldEnd];	
			
			ApplySurface(@"Floor");

			[self drawRulerBetween:lfoot andP2:rfoot];
			//[self drawRulerBetween:rhand andP2:lhand];

			PopSurface();

		}
	}
	
	if(PropF(@"ruler3") > 0){
		
		ofxPoint3f lfoot, rfoot, lhand, rhand;
		ofxUserGenerator * users = [GetPlugin(Kinect) getUserGenerator];
		if(users->getTrackedUsers().size() > 0){
			ofxTrackedUser * user = users->getTrackedUser(0);
			lfoot = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_leg.worldEnd];
			rfoot = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_leg.worldEnd];
			lhand = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_arm.worldEnd];
			rhand = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_arm.worldEnd];	
			
			ApplySurface(@"Floor");
			
			ofxVec3f v = lhand - rhand;
			ofxVec2f v2 = ofxVec2f(v.x,v.z);
			
			ofSetColor(255, 255, 255);
			ofRect(0, 0, Aspect(@"Floor",0), v2.length()*PropF(@"handscale"));
			
			PopSurface();
			
		}
	}
	
}
@end
