//
//  SceneX.mm
//  malpais
//
//  Created by Malpais on 21/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SceneX.h"

#import "Keystoner.h"

@implementation SceneX

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUMIMAGES-1] named:@"image"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1] named:@"alpha"];
}

-(void) setup{
	for(int i=0;i<NUMIMAGES;i++){
		images[i] = new ofImage();
		images[i]->loadImage([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"scenex%i",i] ofType:@"png" inDirectory:@""] cString]);
	}
}

-(void) draw:(NSDictionary *)drawingInformation{
	glBlendFunc(GL_ONE, GL_ONE);
	ofFill();
	if(PropF(@"alpha") > 0){
		ofSetColor(PropF(@"alpha")*255, PropF(@"alpha")*255, PropF(@"alpha")*255);
		images[PropI(@"image")]->draw(0, 0,1,1);
	}
	
	
}
@end
