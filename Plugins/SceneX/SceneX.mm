#import "SceneX.h"

#import "Keystoner.h"

@implementation SceneX

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:NUMIMAGES-1] named:@"image"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1] named:@"alpha"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1 maxValue:1] named:@"backline1"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1 maxValue:1] named:@"backline2"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1 maxValue:1] named:@"backline3"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1 maxValue:1] named:@"backline4"];
	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"drawBackline"];

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
	
	if(PropB(@"drawBackline")){
		ofSetColor(255, 255, 255);
		
		ofSetLineWidth(1);
		ApplySurface(@"Floor");
		
		for(int i=0;i<4;i++){
			float l = [self getBackline:i];
			ofLine(0, l, Aspect(@"Floor",0), l);			
		}
		
		PopSurface();
	}
	
	
	
}

-(float) getBackline:(int)n{
	return PropF(([NSString stringWithFormat:@"backline%i", n]));
}
@end
