#import "Plugin.h"
#include "Filter.h"

#define NUMGRAPHS 11
#define NUMVALUES 3
enum GRAPH_TYPE {
	WIPE_TOP
};

struct Graph {
	Filter filter[NUMVALUES];
	float values[NUMVALUES];
	float valuesGoal[NUMVALUES];
	GRAPH_TYPE type;
};


@interface Statestik : ofPlugin {
	NSMutableArray * surveyData;
	ofTrueTypeFont * font;
	vector<Graph> graphs;
	
	float lineTime;
}
@property (readwrite, retain) NSMutableArray * surveyData;

-(float) aspect;

@end
