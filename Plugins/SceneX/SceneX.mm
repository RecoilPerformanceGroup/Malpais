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

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"backline1")){
		backlinesCache[0] = PropF(@"backline1");	
	}
	if(object == Prop(@"backline2")){
		backlinesCache[1] = PropF(@"backline2");	
	}
	if(object == Prop(@"backline3")){
		backlinesCache[2] = PropF(@"backline3");	
	}
	if(object == Prop(@"backline4")){
		backlinesCache[3] = PropF(@"backline4");	
	}
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
	return backlinesCache[n-1];
}
@end
