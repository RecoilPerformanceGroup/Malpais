//
//  Voice.mm
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#import "Box.h"
#import "Keystoner.h"





@implementation Box


-(void) initPlugin{
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"alpha"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"level"];
	
	[Prop(@"level") setMidiSmoothing:0.7];
	[Prop(@"alpha") setMidiSmoothing:0.7];

	[self assignMidiChannel:13];
}

-(void) setup{
	
}


-(void) update:(NSDictionary *)drawingInformation{
	
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	//ofEnableAlphaBlending();
	ofDisableAlphaBlending();
	
	float level = PropF(@"level");
	
	ApplySurface(@"Wall");{
		//cout<<PropF(@"alpha")*255.0<<endl;
//		glColor4d(255, 255, 255, PropF(@"alpha")*1.0);
		ofSetColor(255.0*PropF(@"alpha"), 255.0*PropF(@"alpha"), 255.0*PropF(@"alpha"), 255.0);
		ofFill();
		
		ofRect(0, 1.0-level, [self aspect], level);
		
		
	} PopSurface();
	
}

-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Wall" viewNumber:0 projectorNumber:1] aspect] floatValue];
}



@end
