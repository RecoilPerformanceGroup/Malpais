#import "Plugin.h"
#include "Filter.h"

#define NUMGRAPHS 11
#define NUMVALUES 10
enum GRAPH_TYPE {
	WIPE_TOP
};

enum filterIndexes {
	posY,
	sizeY,
	posX,
	sizeX,
	r,
	g,
	b,
	a,
	dotOffset,
	percentage
};

struct Graph {
	Filter filter[NUMVALUES];
	float values[NUMVALUES];
	float valuesGoal[NUMVALUES];
	float filterDelay[NUMVALUES];
	float time;
	GRAPH_TYPE type;
};


@interface Statestik : ofPlugin {
	NSMutableArray * surveyData;
	ofTrueTypeFont * font;
	vector<Graph> graphs;

	float lineTime;
	
	int graphCounter;
}
@property (readwrite, retain) NSMutableArray * surveyData;

-(float) aspect;

@end
