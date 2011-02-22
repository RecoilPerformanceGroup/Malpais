#import "Statestik.h"
#include "Keystoner.h"


@implementation Statestik
@synthesize surveyData;

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:10] named:@"displayGraph"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1] named:@"percentageScale"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"lineStart"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:3] named:@"lineStyleWidth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:3] named:@"lineStyleDotsize"];
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"displayGraph")){
		[[globalController openglLock] lock];
		int n = PropI(@"displayGraph");
		while(n < graphs.size()){
			graphs.pop_back();
		}
		while(n > graphs.size()){
			Graph newGraph;
			
			switch (graphs.size()) {
				case 0:
					newGraph.filter[0].setStartValue(1);
					newGraph.filter[1].setStartValue(0);
					newGraph.filter[2].setStartValue([self aspect]);
					newGraph.valuesGoal[0] = 0.4;
					newGraph.valuesGoal[1] = 0;
					newGraph.valuesGoal[2] = [self aspect];
					newGraph.type = WIPE_TOP;					
					break;
				case 1:
					newGraph.filter[0].setStartValue(graphs[0].values[0]);
					newGraph.filter[1].setStartValue([self aspect]*0.5);
					newGraph.filter[2].setStartValue([self aspect]*0.5);
					newGraph.valuesGoal[0] = 0.6;
					newGraph.valuesGoal[1] = [self aspect]*0.5;
					newGraph.valuesGoal[2] = [self aspect]*0.5;
					
					
					newGraph.type = WIPE_TOP;
					
					break;
					
				default:
					break;
			}
			
			graphs.push_back(newGraph);
		}
		[[globalController openglLock] unlock];		
	}
}

-(void) setup{
	font = new ofTrueTypeFont();
	font->loadFont([[[NSBundle mainBundle] pathForResource:@"ApexNew-Bold" ofType:@"otf" inDirectory:@""] cString], 100);
	
}

-(void) update:(NSDictionary *)drawingInformation{
	for(int i=0;i<graphs.size();i++){
		for(int j=0;j<NUMVALUES;j++){
			graphs[i].values[j] = graphs[i].filter[j].filter(graphs[i].valuesGoal[j]);
		}
	}
}

-(void) draw:(NSDictionary *)drawingInformation{
	ApplySurface(@"Floor");{
		ofFill();
		ofSetColor(255, 255, 255);
		for(int i=0;i<graphs.size();i++){
			switch (graphs[i].type) {
				case WIPE_TOP:
					ofRect(graphs[i].values[1], 1-graphs[i].values[0], graphs[i].values[2], graphs[i].values[0]);
					break;
				default:
					break;
			}
		}	
		
		if(graphs.size() == 0){
			ofRect(0, 0, [self aspect], 1);
		}
	} PopSurface();
	
	
	ApplySurface(@"Wall");{		
		if(graphs.size() > 0){
			glPushMatrix();{
				ofSetColor(255, 255, 255);
				ofFill();
				//glTranslated(0.1, 0.5, 0);
				
				float p = graphs[graphs.size()-1].values[0]*100.0;
				string s = ofToString(p, 1)+"%";
				
				float w = font->getStringBoundingBox(s, 0, 0).width;
				float h = font->getStringBoundingBox(s, 0, 0).height;
				
				
				glTranslated(Aspect(@"Wall",0)*0.5, 0.5, 0.0);
				glScaled(0.02*PropF(@"percentageScale"), 0.02*PropF(@"percentageScale"), 1.0);
				
				glTranslated(-w/2.0, 50, 0);
				font->drawString(s, 0, 0);		
				
				
				
			}glPopMatrix();
			
		}
	}PopSurface();
	
	//Line 
	if(graphs.size() > 0){
		ofSetColor(255, 255, 255);
		ofFill();
		
		float middle = graphs[graphs.size()-1].values[2]/2.0 + graphs[graphs.size()-1].values[1];
		middle /= [self aspect];
		float h = 1-graphs[graphs.size()-1].values[0] - 0.05;
		
		
		glLineWidth(PropF(@"lineStyleWidth"));
		glLineStipple(PropI(@"lineStyleDotsize"), 0xAAAA);
		glEnable(GL_LINE_STIPPLE);
		
		ApplySurface(@"Wall");{	
			
			glBegin(GL_LINES);{
				glVertex2f(middle*Aspect(@"Wall",0), 0.7);
				glVertex2f(middle*Aspect(@"Wall",0), 1);
			}glEnd();
		}PopSurface();
		
		ApplySurface(@"Floor");{
			ofSetColor(255, 255, 255);
			ofFill();
			
			glBegin(GL_LINE_STRIP);{
				glVertex2f(middle*[self aspect], 0);
				glVertex2f(middle*[self aspect], h);
			}glEnd();
			
			ofCircle(middle*[self aspect], h, 0.01);
			
		}PopSurface();
		
	}
}


-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}

@end
