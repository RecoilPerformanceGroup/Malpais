#import "Statestik.h"
#include "Keystoner.h"
#include "SceneX.h"

@implementation Statestik
@synthesize surveyData;

-(void) initPlugin{
	[self assignMidiChannel:10];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:20] named:@"displayGraph"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1] named:@"percentageScale"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:2.0 minValue:1.0 maxValue:4.0] named:@"backlineNo"];

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
					[Prop(@"backlineNo") setIntValue:2];
					newGraph.filter[sizeY].setStartValue(1);
					newGraph.filter[posX].setStartValue(0);
					newGraph.filter[sizeX].setStartValue([self aspect]);
					newGraph.valuesGoal[sizeY] = 0.6;
					newGraph.values[sizeY] = 1;
					newGraph.valuesGoal[percentage] = 0.338;
					newGraph.valuesGoal[posX] = 0;
					newGraph.valuesGoal[sizeX] = [self aspect];
					newGraph.type = WIPE_TOP;	
					newGraph.filterDelay[sizeY] = 1;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					hideLine = NO;
					
					graphs.push_back(newGraph);
					
					break;
				case 1:
					graphs[0].valuesGoal[sizeY] = 0.8;
					graphs[0].valuesGoal[percentage] = 0.587;
					
					break;
				case 2:
					graphs[0].valuesGoal[sizeY] = 0.5;
					graphs[0].valuesGoal[percentage] = 0.254;					
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
					newGraph.valuesGoal[sizeY] = 0.145;
					newGraph.valuesGoal[posX] = [self aspect]*0.5;
					newGraph.valuesGoal[sizeX] = [self aspect]*0.5;
					
					newGraph.filterDelay[sizeY] = 0.9;
					newGraph.filterDelay[percentage] = 0.9;

					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 0;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					newGraph.valuesGoal[percentage] = 0.045;
					
					graphs.push_back(newGraph);
					break;
					
				case 4:
					
					graphs[0].valuesGoal[posX] = -2*[self aspect];
					graphs[1].valuesGoal[posX] = -2*[self aspect]+0.5*[self aspect];
					
					newGraph.filterDelay[sizeY] = 0.0;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*1);
					newGraph.valuesGoal[sizeY] = 0.254;
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
					newGraph.valuesGoal[percentage] = 0.154;

					graphs.push_back(newGraph);
					
					
					
					break;
					
				case 5:				
					newGraph.filterDelay[sizeY] = 0.0;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*1);
					newGraph.valuesGoal[sizeY] = 0.297;
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
					newGraph.valuesGoal[percentage] = 0.197;

					graphs[2].valuesGoal[posY] = newGraph.valuesGoal[sizeY];

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
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(0);
					newGraph.valuesGoal[g] = 0;
					newGraph.filter[b].setStartValue(0);
					newGraph.valuesGoal[b] = 0;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					newGraph.valuesGoal[dotOffset] = 0.1;
					newGraph.valuesGoal[percentage] = 0.303;
					graphs.push_back(newGraph);	
					
					
					graphs[2].valuesGoal[posY] += newGraph.valuesGoal[sizeY];
					graphs[3].valuesGoal[posY] += newGraph.valuesGoal[sizeY];

					
					break;
					
				case 7:					
					graphs[2].valuesGoal[posY] += 1.1;
					graphs[3].valuesGoal[posY] += 1.1;
					graphs[4].valuesGoal[posY] += 1.1;
					
					newGraph.filterDelay[sizeY] = 0.5;
					newGraph.filterDelay[percentage] = 0.5;

					newGraph.values[sizeY] = 0;
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.0);
					newGraph.filter[sizeX].setStartValue([self aspect]*0.5);
					newGraph.valuesGoal[sizeY] = 0.224;
					newGraph.valuesGoal[percentage] = 0.27;
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
					newGraph.valuesGoal[sizeY] = 0.75;
					newGraph.valuesGoal[percentage] = 0.741;
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
					
					
				case 9:					
					newGraph.filter[sizeY].setStartValue(0);
					newGraph.filter[posX].setStartValue([self aspect]*0.33333*2);
					newGraph.filter[sizeX].setStartValue([self aspect]*0.33333);
					newGraph.valuesGoal[sizeY] = 0.10;
					newGraph.valuesGoal[percentage] = 0.032;
					newGraph.valuesGoal[posX] = [self aspect]*0.33333*2;
					newGraph.valuesGoal[sizeX] = [self aspect]*0.33333;					
					newGraph.type = WIPE_TOP;
					
					newGraph.filter[r].setStartValue(255);
					newGraph.valuesGoal[r] = 255;
					newGraph.filter[g].setStartValue(255);
					newGraph.valuesGoal[g] = 255;
					newGraph.filter[b].setStartValue(255);
					newGraph.valuesGoal[b] = 255;
					newGraph.filter[a].setStartValue(255);
					newGraph.valuesGoal[a] = 255;
					
					graphs[5].valuesGoal[posX] = 0;
					graphs[6].valuesGoal[posX] = [self aspect]*0.3333;
					graphs[5].valuesGoal[sizeX] = [self aspect]*0.3333;
					graphs[6].valuesGoal[sizeX] = [self aspect]*0.3333;

					
					
					graphs.push_back(newGraph);	
					
					break;
				
				case 10:		
					hideLine = YES;
					
					graphs[5].time = 0;
					graphs[5].filterDelay[sizeY] = 0.6;
					graphs[5].valuesGoal[sizeY] = -0.2;
					
					graphs[6].time = 0;
					graphs[6].filterDelay[sizeY] = 0.6;
					graphs[6].valuesGoal[sizeY] = -0.2;
					
					graphs[7].time = 0;
					graphs[7].filterDelay[sizeY] = 0.6;
					graphs[7].filterDelay[percentage] = 0.6;

					graphs[7].valuesGoal[sizeY] = 0.2;
					graphs[7].valuesGoal[sizeX] = [self aspect];
					graphs[7].valuesGoal[posX] = 0;
					graphs[7].valuesGoal[percentage] = 0.089;
					break;
					
				case 11:		
					graphs[6].valuesGoal[sizeX] = 0.5*[self aspect];
					graphs[6].valuesGoal[posX] = 0.5*[self aspect];
					graphs[7].valuesGoal[sizeY] = 0.4;
					graphs[7].valuesGoal[percentage] = 0.337;
					break;
				case 12:		
					graphs[6].valuesGoal[sizeY] = 0.7;
					graphs[7].valuesGoal[percentage] = 0.628;
					break;
				case 13:		
					graphs[6].valuesGoal[sizeY] = -0.2;
					
					graphs[7].time = 0;
					graphs[7].filterDelay[sizeY] = 0.6;
					graphs[7].filterDelay[percentage] = 0.6;
					graphs[7].valuesGoal[sizeY] = 0.5;
					graphs[7].valuesGoal[percentage] = 0.35;
					
					break;
					
				case 14:		

					graphs[7].valuesGoal[sizeY] = 0.1;
					graphs[7].valuesGoal[percentage] = 0.029;
					
					break;
			
				case 15:		
					graphs[7].valuesGoal[sizeY] = 1;
					graphs[7].valuesGoal[percentage] = 0.98;
					
					break;
					
				case 16:		
					graphs[7].valuesGoal[sizeY] = -0.1;
					
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
	
	float backLine = [GetPlugin(SceneX) getBackline:(int)round(PropF(@"backlineNo"))];
	
	ApplySurface(@"Floor");{

		glTranslatef(0, backLine, 0);
		glScalef(1, 1.0-backLine, 0);
		
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
		ofRect(0, 0, -1, 1); // left
		ofRect([self aspect], backLine, 1, 1); //right
		
		ofRect(0, 0, 1, -1); //top
		ofRect(0, 1, 1, 1);//bottom
		
	} PopSurface();
	
	
	ofEnableAlphaBlending();
	ApplySurface(@"Wall");{		
		if(graphs.size() > 0){
			glPushMatrix();{
				ofSetColor(255, 255, 255, p*255.0);
				ofFill();
				//glTranslated(0.1, 0.5, 0);
				
				float p = graphs[graphs.size()-1].values[percentage]*100.0;
				string s = ofToString(p, 1)+"%";
				
				float w = font->getStringBoundingBox(s, 0, 0).width;
				float h = font->getStringBoundingBox(s, 0, 0).height;
				
				
				glTranslated(Aspect(@"Wall",1)*0.5, 0.5, 0.0);
				glScaled(0.02*PropF(@"percentageScale"), 0.02*PropF(@"percentageScale"), 1.0);
				
				glTranslated(-w/2.0, 50, 0);
				font->drawString(s, 0, 0);		
				
				
				
			}glPopMatrix();
			
		}
	}PopSurface();
	
	//Line 
	if(graphs.size() > 0 && !hideLine){
		ofSetColor(255, 255, 255);
		ofFill();
		
		float middle = graphs[graphs.size()-1].values[sizeX]/2.0 + graphs[graphs.size()-1].values[posX];
		middle /= [self aspect];
		float h = 1-graphs[graphs.size()-1].values[sizeY] - 0.05 + graphs[graphs.size()-1].values[dotOffset];
		
		float wallFloorFactor = (float)Aspect(@"Wall",1) / Aspect(@"Floor",0);
		float wallL = 1-0.7;
		float floorL = h * wallFloorFactor;
		
		float switchPercentage = wallL/(wallL + floorL);
		
		float wallP = ofClamp(p * 1.0/switchPercentage , 0, 1);
		float floorP = ofClamp((p-switchPercentage) * 1.0/(1-switchPercentage) , 0, 1);
		
		float lineStyleWidth = (0.01*PropF(@"lineStyleWidth"))+0.001;
		
		ApplySurface(@"Wall");{
			
			float lineStart = 1-wallL+0.04;
			float lineEnd = 1-wallL+wallL*wallP;
			float lineX = (middle*Aspect(@"Wall",1))-(0.5*lineStyleWidth);
			float aspect = Aspect(@"Wall",1);

			for (float lineY=lineStart; lineY < lineEnd; lineY+=(2*lineStyleWidth)) {
				ofRect(lineX, lineY, lineStyleWidth*aspect, lineStyleWidth);
			}

		}PopSurface();
		
		if(floorP > 0){
			ApplySurface(@"Floor");{

				ofSetColor(255, 255, 255);
				ofFill();
				
				float lineStart = backLine;
				float lineEnd = ofMap(h*floorP, 0, 1.0, backLine, 1, false);
				float lineX = (middle*[self aspect])-(0.5*lineStyleWidth);
				
				float aspect = Aspect(@"Floor",0);
				
				for (float lineY=lineStart; lineY < lineEnd; lineY+=(2*lineStyleWidth)) {
					ofRect(lineX, lineY, lineStyleWidth*aspect, lineStyleWidth);
				}
				
				ofCircle(middle*[self aspect], ofMap(h*floorP, 0, 1.0, backLine, 1, false), 0.01);
				
			}PopSurface();
		}
		
		glDisable(GL_LINE_STIPPLE);
		
	}
}


-(float) aspect{
	return [[[GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0] aspect] floatValue];
}

@end
