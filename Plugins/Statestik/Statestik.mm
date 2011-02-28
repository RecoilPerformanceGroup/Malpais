#import "Statestik.h"
#include "Keystoner.h"


@implementation Statestik
@synthesize surveyData;

-(void) initPlugin{
	[self assignMidiChannel:10];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:10] named:@"displayGraph"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1] named:@"percentageScale"];
	
	//	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"lineStart"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:3] named:@"lineStyleWidth"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:3] named:@"lineStyleDotsize"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"lineSpeed"];
	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"showNumber"];
	graphCounter = 0;
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"displayGraph")){
		[[globalController openglLock] lock];
		int n = PropI(@"displayGraph");
		if(n == 0){
			graphs.clear();
			graphCounter = 0;
		}
		while(n > graphCounter){
			cout<<n<<"  >  "<<graphCounter<<endl;
			Graph newGraph;					
			
			switch (graphCounter) {
				case 0:
					newGraph.filter[sizeY].setStartValue(1);
					newGraph.filter[posX].setStartValue(0);
					newGraph.filter[sizeX].setStartValue([self aspect]);
					newGraph.valuesGoal[sizeY] = 0.338;
					newGraph.valuesGoal[posX] = 0;
					newGraph.valuesGoal[sizeX] = [self aspect];
					newGraph.type = WIPE_TOP;	
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					
					graphs.push_back(newGraph);
					
					break;
				case 1:
					graphs[0].valuesGoal[sizeY] = 0.587;
					
					break;
				case 2:
					graphs[0].valuesGoal[sizeY] = 0.254;
					
					/*		graphs[0].valuesGoal[posX] = -2*[self aspect];
					 graphs[1].valuesGoal[posX] = -2*[self aspect]+0.5*[self aspect];
					 
					 newGraph.filterDelay[sizeY] = 0.7;
					 newGraph.filter[sizeY].setStartValue(0);
					 newGraph.filter[posX].setStartValue([self aspect]*0.1);
					 newGraph.filter[sizeX].setStartValue([self aspect]*0.8);
					 newGraph.valuesGoal[sizeY] = 0.6;
					 newGraph.valuesGoal[posX] = [self aspect]*0.1;
					 newGraph.valuesGoal[sizeX] = [self aspect]*0.8;					
					 newGraph.type = WIPE_TOP;
					 */
					break;
					
				case 3:
					graphs[0].valuesGoal[sizeX] = [self aspect]*0.5;
					graphs[0].filter[sizeX].setStartValue([self aspect]*0.5);
					graphs[0].values[sizeX] = [self aspect]*0.5;
					
					newGraph.filter[sizeY].setStartValue(graphs[0].values[sizeY]);
					newGraph.values[sizeY] = graphs[0].values[sizeY];
					newGraph.filter[posX].setStartValue([self aspect]*0.5);
					newGraph.filter[sizeX].setStartValue([self aspect]*0.5);
					newGraph.valuesGoal[sizeY] = 0.045;
					newGraph.valuesGoal[posX] = [self aspect]*0.5;
					newGraph.valuesGoal[sizeX] = [self aspect]*0.5;
					
					newGraph.filterDelay[sizeY] = 0.9;
					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 0;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					graphs.push_back(newGraph);
					break;
					
				case 4:
					
					graphs[0].valuesGoal[posX] = -2*[self aspect];
					graphs[1].valuesGoal[posX] = -2*[self aspect]+0.5*[self aspect];
					
					newGraph.filterDelay[sizeY] = 0.7;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*1);
					newGraph.valuesGoal[sizeY] = 0.154;
					newGraph.valuesGoal[posX] = [self aspect]*0.0;
					newGraph.valuesGoal[sizeX] = [self aspect]*1;	
					newGraph.values[sizeY] = 0;
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(20);
					newGraph.valuesGoal[r] = 20;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(20);
					newGraph.valuesGoal[b] = 20;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					graphs.push_back(newGraph);
					
					
					
					break;
					
				case 5:				
					newGraph.filterDelay[sizeY] = 0.0;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*1);
					newGraph.valuesGoal[sizeY] = 0.197;
					newGraph.valuesGoal[posX] = [self aspect]*0.0;
					newGraph.valuesGoal[sizeX] = [self aspect]*1;					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(0);
					newGraph.valuesGoal[r] = 0;
					newGraph.filter[g].setStartValue(0);
					newGraph.valuesGoal[g] = 0;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					newGraph.valuesGoal[dotOffset] = 0.1;
					
					graphs[2].valuesGoal[posY] = newGraph.valuesGoal[sizeY];
					graphs[2].valuesGoal[a] = 60.0;					

					graphs.push_back(newGraph);	
					
					
					break;
				
				case 6:				
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*1);
					newGraph.valuesGoal[sizeY] = 0.413;
					newGraph.valuesGoal[posX] = [self aspect]*0.0;
					newGraph.valuesGoal[sizeX] = [self aspect]*1;					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(100);
					newGraph.valuesGoal[r] = 100;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					newGraph.valuesGoal[dotOffset] = 0.1;

					graphs.push_back(newGraph);	
					
					
					graphs[2].valuesGoal[posY] += newGraph.valuesGoal[sizeY];
					graphs[2].valuesGoal[a] = 60.0;					
					graphs[3].valuesGoal[posY] += newGraph.valuesGoal[sizeY];
					graphs[3].valuesGoal[a] = 60.0;					

					
					break;
					
				case 7:					
					graphs[2].valuesGoal[posY] += 1;
					graphs[3].valuesGoal[posY] += 1;
					graphs[4].valuesGoal[posY] += 1;
					
					newGraph.filterDelay[sizeY] = 0.5;
					newGraph.values[sizeY] = 0;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*0.5);
					newGraph.valuesGoal[sizeY] = 0.324;
					newGraph.valuesGoal[posX] = [self aspect]*0.0;
					newGraph.valuesGoal[sizeX] = [self aspect]*0.5;					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					
					graphs.push_back(newGraph);	
					
				
					
					
					break;
					
				case 8:					
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.5);
					newGraph.filter[sizeX].setStartValue([self aspect]*0.5);
					newGraph.valuesGoal[sizeY] = 0.059;
					newGraph.valuesGoal[posX] = [self aspect]*0.5;
					newGraph.valuesGoal[sizeX] = [self aspect]*0.5;					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					
					graphs.push_back(newGraph);	
					
					
					
					
					break;
					
					
				default:
					break;
			}
			graphCounter++;
		}
		
		[[globalController openglLock] unlock];		
	}
}

-(void) setup{
	font = new ofTrueTypeFont();
	font->loadFont([[[NSBundle mainBundle] pathForResource:@"ApexNew-Bold" ofType:@"otf" inDirectory:@""] cString], 100);
	
	lineTime = 0;
	
}

-(void) update:(NSDictionary *)drawingInformation{
	float lineGoal = 0;
	if(PropB(@"showNumber") && lineTime < 1){
		lineTime += 10.0/ofGetFrameRate()*PropF(@"lineSpeed");
		if(lineTime > 1)
			lineTime = 1;
	} else if(lineTime > 0 && !PropB(@"showNumber")){
		lineTime -= 10.0/ofGetFrameRate()*PropF(@"lineSpeed");
		if(lineTime < 0)
			lineTime = 0;
	}
	
	//	lineTime += (lineGoal - lineTime) * 10.0/ofGetFrameRate()*PropF(@"lineSpeed");
	
	for(int i=0;i<graphs.size();i++){
		graphs[i].time += 1.0/ofGetFrameRate();
		for(int j=0;j<NUMVALUES;j++){
			if(graphs[i].filterDelay[j] < graphs[i].time)
				graphs[i].values[j] = graphs[i].filter[j].filter(graphs[i].valuesGoal[j]);
		}
	}
}

-(void) draw:(NSDictionary *)drawingInformation{
	float e = 2.71828182845904523536;
	
	float t = lineTime - 0.5;
	float p = 1.0/(1.0+pow(e,-(t)*10));
	
	
	ApplySurface(@"Floor");{
		ofEnableAlphaBlending();
		
		ofFill();
		for(int i=0;i<graphs.size();i++){
			ofSetColor(graphs[i].values[r], graphs[i].values[g], graphs[i].values[b], graphs[i].values[a]);
			
			switch (graphs[i].type) {
				case WIPE_TOP:
					ofRect(graphs[i].values[posX], 1-graphs[i].values[posY], graphs[i].values[sizeX], -graphs[i].values[sizeY]);
					break;
				default:
					break;
			}
		}	
		
		if(graphs.size() == 0){
			ofSetColor(255, 255, 255,255);
			ofRect(0, 0, [self aspect], 1);
		}
		
		ofDisableAlphaBlending();
		ofSetColor(0, 0, 0,255);
		ofRect(0, 0, -1, 1);
		ofRect([self aspect], 0, 1, 1);
		
		ofRect(0, 0, 1, -1);
		ofRect(0, 1, 1, 1);
		
	} PopSurface();
	
	
	ofEnableAlphaBlending();
	ApplySurface(@"Wall");{		
		if(graphs.size() > 0){
			glPushMatrix();{
				ofSetColor(255, 255, 255, p*255.0);
				ofFill();
				//glTranslated(0.1, 0.5, 0);
				
				float p = graphs[graphs.size()-1].values[sizeY]*100.0;
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
		
		float middle = graphs[graphs.size()-1].values[sizeX]/2.0 + graphs[graphs.size()-1].values[posX];
		middle /= [self aspect];
		float h = 1-graphs[graphs.size()-1].values[sizeY] - 0.05 + graphs[graphs.size()-1].values[dotOffset];
		
		float wallFloorFactor = (float)Aspect(@"Wall",0) / Aspect(@"Floor",0);
		float wallL = 1-0.7;
		float floorL = h * wallFloorFactor;
		
		float switchPercentage = wallL/(wallL + floorL);
		
		float wallP = ofClamp(p * 1.0/switchPercentage , 0, 1);
		float floorP = ofClamp((p-switchPercentage) * 1.0/(1-switchPercentage) , 0, 1);
		
		glLineWidth(PropF(@"lineStyleWidth"));
		glLineStipple(PropI(@"lineStyleDotsize"), 0xAAAA);
		glEnable(GL_LINE_STIPPLE);
		
		ApplySurface(@"Wall");{				
			glBegin(GL_LINES);{
				glVertex2f(middle*Aspect(@"Wall",0), 1-wallL);
				glVertex2f(middle*Aspect(@"Wall",0), 1-wallL+wallL*wallP);
			}glEnd();
		}PopSurface();
		
		if(floorP > 0){
			ApplySurface(@"Floor");{
				ofSetColor(255, 255, 255);
				ofFill();
				
				glBegin(GL_LINE_STRIP);{
					glVertex2f(middle*[self aspect], 0);
					glVertex2f(middle*[self aspect], h*floorP);
				}glEnd();
				
				ofCircle(middle*[self aspect], h*floorP, 0.01);
				
			}PopSurface();
		}
		
	}
}


-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}

@end
