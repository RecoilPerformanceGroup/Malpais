#import "Kinect.h"

#import "Keystoner.h"
#include <algorithm>


//--------------------
//-- Persistent Blob --
//--------------------



@implementation PersistentBlob
@synthesize blobs;
-(id) init{
	if([super init]){
		timeoutCounter = 0;
		centroid = new ofxPoint2f;
		lastcentroid = new ofxPoint2f;
		centroidV = new ofxVec2f;
		centroidFiltered = new ofxPoint3f;
		
		centroidFilter[0] = new Filter();
		centroidFilter[1] = new Filter();					
		centroidFilter[2] = new Filter();					
		
		centroidFilter[0]->setNl(9.413137469932821686e-04, 2.823941240979846506e-03, 2.823941240979846506e-03, 9.413137469932821686e-04);
		centroidFilter[0]->setDl(1, -2.5818614306773719263, 2.2466666427559748864, -.65727470210265670262);
		centroidFilter[1]->setNl(9.413137469932821686e-04, 2.823941240979846506e-03, 2.823941240979846506e-03, 9.413137469932821686e-04);
		centroidFilter[1]->setDl(1, -2.5818614306773719263, 2.2466666427559748864, -.65727470210265670262);
		centroidFilter[2]->setNl(9.413137469932821686e-04, 2.823941240979846506e-03, 2.823941240979846506e-03, 9.413137469932821686e-04);
		centroidFilter[2]->setDl(1, -2.5818614306773719263, 2.2466666427559748864, -.65727470210265670262);
		
		blobs = [[NSMutableArray array] retain];
		
	}
	return self;
}

-(ofxPoint2f) getLowestPoint{
	ofxPoint2f low;
	Blob * blob;
	for(blob in blobs){
		if([blob getLowestPoint].y > low.y){
			low = [blob getLowestPoint];
		}
	}
	return low;
}

-(ofxPoint3f) centroidFiltered{
	//return ofxPoint2f(centroidFiltered[0], centroidFiltered[1]);
	return *centroidFiltered;
}
-(void) dealloc {
	delete centroid;
	delete lastcentroid;
	delete centroidV;
	[blobs removeAllObjects];
	[blobs release];
	[super dealloc];
}

@end


//--------------------
//-- Blob --
//--------------------

@implementation Blob
@synthesize cameraId, originalblob, floorblob, segment, avgDepth;

-(id)initWithMouse:(ofPoint*)point{
	if([super init]){
		blob = new ofxCvBlob();
		floorblob = new ofxCvBlob();
		
		originalblob = new ofxCvBlob();
		//		originalblob->area = blob->area = _blob->area;
		//      originalblob->length = blob->length = _blob->length ;
		//       originalblob->boundingRect = blob->boundingRect = _blob->boundingRect;
        floorblob->centroid = originalblob->centroid = blob->centroid = *point;
		//        originalblob->hole = blob->hole = _blob->hole;
		
		floorblob->nPts = originalblob->nPts = blob->nPts = 30;
		for(int i=0;i<30;i++){
			float a = TWO_PI*i/30.0;
			blob->pts.push_back(ofPoint(cos(a)*0.05+point->x, sin(a)*0.05+point->y)); 
		}
		floorblob->pts =  originalblob->pts = blob->pts ;
		
		
	} 
	return self;
}


-(ofxPoint2f) getLowestPoint{
	
	if(low)
		return *low;
	else {
		for(int u=0;u< [self nPts];u++){
			if(!low || [self pts][u].y > low->y){
				if(low){
					low->x = [self pts][u].x;
					low->y = [self pts][u].y;
				} else {
					low = new ofxPoint2f([self pts][u]);
				}
			}
		}
		return *low;
	}
	
}

-(id)initWithBlob:(ofxCvBlob*)_blob{
	if([super init]){
		blob = new ofxCvBlob();
		floorblob = new ofxCvBlob();
		
		originalblob = new ofxCvBlob();
		originalblob->area = blob->area = _blob->area;
        originalblob->length = blob->length = _blob->length ;
        originalblob->boundingRect = blob->boundingRect = _blob->boundingRect;
        originalblob->centroid = blob->centroid = _blob->centroid;
        originalblob->hole = blob->hole = _blob->hole;
		
		floorblob->nPts = originalblob->nPts = blob->nPts = _blob->nPts;
		floorblob->pts =  originalblob->pts = blob->pts = _blob->pts; 
		
	} 
	return self;
}

- (void)dealloc {
	delete blob;
	delete floorblob;
	delete originalblob;
    [super dealloc];
}

-(void) normalize:(int)w height:(int)h{
	for(int i=0;i<blob->nPts;i++){
		blob->pts[i].x /= (float)w;
		blob->pts[i].y /= (float)h;
	}
	blob->area /= (float)w*h;
	blob->centroid.x /=(float) w;
	blob->centroid.y /= (float)h;
	blob->boundingRect.width /= (float)w; 
	blob->boundingRect.height /= (float)h; 
	blob->boundingRect.x /= (float)w; 
	blob->boundingRect.y /= (float)h; 
	
	originalblob->pts = blob->pts;
	originalblob->area = blob->area;
	originalblob->centroid = blob->centroid;
	originalblob->boundingRect = blob->boundingRect;
}

-(vector <ofPoint>)pts{
	return blob->pts;
}
-(int)nPts{
	return blob->nPts;	
}
-(ofPoint)centroid{
	return blob->centroid;		
}
-(float) area{
	return blob->area;		
}
-(float)length{
	return blob->length;		
}
-(ofRectangle) boundingRect{
	return blob->boundingRect;	
}
-(BOOL) hole{
	return blob->hole;		
}

@end




//--------------------
//-- Kinect plugin --
//--------------------



@implementation Kinect
@synthesize blobs, persistentBlobs;

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-30 maxValue:30] named:@"angle1"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-30 maxValue:30] named:@"angle2"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-30 maxValue:30] named:@"angle3"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:4] named:@"priority0"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:4] named:@"priority1"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:4] named:@"priority2"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:500] named:@"segmentSize"];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:10000] named:@"minDistance"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10000 minValue:0 maxValue:10000] named:@"maxDistance"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-10000 maxValue:10000] named:@"yMin"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1000 minValue:0 maxValue:10000] named:@"yMax"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"persistentDist"];	
	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:1.0] named:@"blobTracking"];
	
	if([customProperties valueForKey:@"point0a"] == nil){
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point0a"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point0b"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point0x"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point0y"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point0z"];
		
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"point1a"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point1b"];
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"point1x"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point1y"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point1z"];
		
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point2a"];
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"point2b"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point2x"];
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"point2y"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"point2z"];		
		
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"proj0x"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"proj0y"];
		
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"proj1x"];
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"proj1y"];
		
		[customProperties setValue:[NSNumber numberWithInt:0] forKey:@"proj2x"];
		[customProperties setValue:[NSNumber numberWithInt:1] forKey:@"proj2y"];
		
	}
	
	stop = NO;
	draggedPoint = -1;
	
	for(int i=0;i<3;i++){
		dancers[i].userId = -1;
		dancers[i].state = 0;
	}
	
	blobs = [[NSMutableArray array] retain];
	threadBlobs = [[NSMutableArray array] retain];
	persistentBlobs = [[NSMutableArray array] retain];
	
	projPointCache[0] = nil;
	projPointCache[1] = nil;
	projPointCache[2] = nil;

	point2Cache[0] = nil;
	point2Cache[1] = nil;
	point2Cache[2] = nil;

	point3Cache[0] = nil;
	point3Cache[1] = nil;
	point3Cache[2] = nil;
	
	
}

-(void) setup{
	//ofSetLogLevel(OF_LOG_VERBOSE);	
	context.setup();
	kinectConnected = depth.setup(&context);
	
	if(kinectConnected){
	//	users.setup(&context, &depth);		
		[self calculateMatrix];	 
	}
	
	thread = [[NSThread alloc] initWithTarget:self
									 selector:@selector(performBlobTracking:)
									   object:nil];
	pthread_mutex_init(&mutex, NULL);
	pthread_mutex_init(&drawingMutex, NULL);
	threadUpdateContour = NO;
	
	for(int i=0;i<NUM_SEGMENTS;i++){
		grayImage[i] = new ofxCvGrayscaleImage();
		threadGrayImage[i] = new ofxCvGrayscaleImage();
		
		grayImage[i]->allocate(640,480);
		threadGrayImage[i]->allocate(640,480);
	}
	
	threadedPixels = new XnDepthPixel[640*480];
	threadedPixelsSorted = new XnDepthPixel[640*480];
	
	contourFinder = new ofxCvContourFinder();
	
	[thread start];
}

-(void) update:(NSDictionary *)drawingInformation{
	if(!stop && kinectConnected){
		context.update();
		depth.update();
		//users.update();		
		
		//Blob tracking
		if(PropB(@"blobTracking")){
			xn::DepthMetaData dmd;
			depth.getXnDepthGenerator().GetMetaData(dmd);	
			const XnDepthPixel* pixels = dmd.Data();
			
			pthread_mutex_lock(&drawingMutex);
			pthread_mutex_lock(&mutex);
			if(!threadUpdateContour){				
				
				memcpy(threadedPixels, pixels, 640*480*sizeof(XnDepthPixel));
				
				for(int i=0;i<NUM_SEGMENTS;i++){
					*grayImage[i] = *threadGrayImage[i];
				}
				
				[self setBlobs:threadBlobs];
				
				threadUpdateContour = YES;				
			}
			
			pthread_mutex_unlock(&mutex);
			
			
			
			//Clear blobs
			for(PersistentBlob * pblob in persistentBlobs){
				ofxPoint2f p = pblob->centroid - pblob->lastcentroid;
				pblob->centroidV->x = p.x;
				pblob->centroidV->y = p.y;
				pblob->lastcentroid = pblob->centroid ;
				[pblob->blobs removeAllObjects];
				pblob->age ++;
			}
			
			for(Blob * blob in blobs){
				bool blobFound = false;
				float shortestDist = 0;
				int bestId = -1;
				
				ofxPoint3f centroid = ofxPoint3f([blob centroid].x*640, [blob centroid].y*480, [blob avgDepth]);
				ofxPoint3f floorCentroid3 = [self convertWorldToFloor:[self convertKinectToWorld:centroid]];
				ofxPoint2f floorCentroid = ofxPoint2f(floorCentroid3.x, floorCentroid3.z);
				
				//Går igennem alle grupper for at finde den nærmeste gruppe som blobben kan tilhøre
				//Magisk høj dist: 0.3
				
				/*for(int u=0;u<[persistentBlobs count];u++){
				 //Giv forrang til døde persistent blobs
				 if(((PersistentBlob*)[persistentBlobs objectAtIndex:u])->timeoutCounter > 5){
				 float dist = centroid.distance(*((PersistentBlob*)[persistentBlobs objectAtIndex:u])->centroid);
				 if(dist < [persistentSlider floatValue]*0.5 && (dist < shortestDist || bestId == -1)){
				 bestId = u;
				 shortestDist = dist;
				 blobFound = true;
				 }
				 }
				 }*/
				if(!blobFound){						
					for(int u=0;u<[persistentBlobs count];u++){
						//						ofxPoint2f centroidPoint = [GetPlugin(ProjectionSurfaces) convertPoint:*((PersistentBlob*)[persistentBlobs objectAtIndex:u])->centroid fromProjection:"Front" surface:"Floor"];
						ofxPoint2f centroidPoint = *((PersistentBlob*)[persistentBlobs objectAtIndex:u])->centroid;
						float dist = floorCentroid.distance(centroidPoint);
						if(dist < PropF(@"persistentDist") && (dist < shortestDist || bestId == -1)){
							bestId = u;
							shortestDist = dist;
							blobFound = true;
						}
					}
				}
				
				if(blobFound){	
					//					[currrentPblobCounter setIntValue:[currrentPblobCounter intValue] +1];
					
					PersistentBlob * bestBlob = ((PersistentBlob*)[persistentBlobs objectAtIndex:bestId]);
					
					//					[bestBlob->blobs removeAllObjects];
					
					//Fandt en gruppe som den her blob kan tilhøre.. Pusher blobben ind
					bestBlob->timeoutCounter = 0;
					[bestBlob->blobs addObject:blob];
					
					//regner centroid ud fra alle blobs i den
					bestBlob->centroid->set(0, 0);
					for(int g=0;g<[bestBlob->blobs count];g++){
						ofxPoint3f kinectCentroid = ofxPoint3f([[bestBlob->blobs objectAtIndex:g] centroid].x*640, [[bestBlob->blobs objectAtIndex:g] centroid].y*480, [[bestBlob->blobs objectAtIndex:g] avgDepth]);
						ofxPoint3f blobCentroid3 = [self convertWorldToFloor:[self convertKinectToWorld:kinectCentroid]];
						ofxPoint2f blobCentroid = ofxPoint2f(blobCentroid3.x, blobCentroid3.z);
						*bestBlob->centroid += blobCentroid;					
					}
					*bestBlob->centroid /= (float)[bestBlob->blobs count];
					
					ofxPoint3f kinectLowestPoint = ofxPoint3f([bestBlob getLowestPoint].x*640, [bestBlob getLowestPoint].y*480, pixels[(int)([bestBlob getLowestPoint].x*640+[bestBlob getLowestPoint].y*480*640)]);
					ofxPoint3f lowestPointFloor = [self convertWorldToFloor:[self convertKinectToWorld:kinectLowestPoint]];
					
					
					bestBlob->centroidFiltered->x = bestBlob->centroidFilter[0]->filter(bestBlob->centroid->x);
					bestBlob->centroidFiltered->y = bestBlob->centroidFilter[1]->filter(lowestPointFloor.y);
					bestBlob->centroidFiltered->y = bestBlob->centroidFilter[1]->filter(lowestPointFloor.y);
					bestBlob->centroidFiltered->y = bestBlob->centroidFilter[1]->filter(lowestPointFloor.y);
					bestBlob->centroidFiltered->z = bestBlob->centroidFilter[2]->filter(bestBlob->centroid->y);
				}
				
				if(!blobFound){
					//Der var ingen gruppe til den her blob, så vi laver en
					PersistentBlob * newB = [[PersistentBlob alloc] init];
					[newB->blobs addObject:blob];
					*newB->centroid = floorCentroid;
					
					ofxPoint3f kinectLowestPoint = ofxPoint3f([newB getLowestPoint].x*640, [newB getLowestPoint].y*480, pixels[(int)([newB getLowestPoint].x*640+[newB getLowestPoint].y*480*640)]);
					ofxPoint3f lowestPointFloor = [self convertWorldToFloor:[self convertKinectToWorld:kinectLowestPoint]];
					
					newB->centroidFilter[0]->setStartValue(floorCentroid.x);
					newB->centroidFilter[1]->setStartValue(lowestPointFloor.y);
					newB->centroidFilter[2]->setStartValue(floorCentroid.y);
					
					*newB->centroidFiltered = *newB->centroid;
					newB->pid = pidCounter++;
					newB->age = 0;
					[persistentBlobs addObject:newB];		
					
					//[newestId setIntValue:pidCounter];
				}
			}		
			
			//Delete all the old pblobs
			for(int i=0; i< [persistentBlobs count] ; i++){
				PersistentBlob * blob = [persistentBlobs objectAtIndex:i];
				blob->timeoutCounter ++;
				if(blob->timeoutCounter > 10){
					[persistentBlobs removeObject:blob];
				}			
			}
			
			pthread_mutex_unlock(&drawingMutex);
		}
		
		vector<ofxTrackedUser*> vusers = users.getFoundUsers(); 
		
		int numberNonstoredUsers = 0;
		
		bool dancerFound[3];
		for(int i=0;i<3;i++)
			dancerFound[i] = false;
		
		for(int i=0;i<vusers.size();i++){
			//------
			//Uncalibrated user
			if(vusers[i]->is_found && !vusers[i]->is_tracked){
				for(int p=1;p<4;p++){
					int dancer = -1;
					for(int d=0;d<3;d++){
						if(PropI(([NSString stringWithFormat:@"priority%i",d])) == p && dancers[i].state == 1){
							//Prioritering passer, og danseren har ikke nogen user tilknyttet, men har en calibration
							dancer = d;
						}
					}
					if(dancer >= 0){
						ofxTrackedUser * user = vusers[i];
						if(users.getXnUserGenerator().GetSkeletonCap().IsCalibrationData(dancer)){
							NSLog(@"Load calibration");
							users.stopPoseDetection(user->id);
							
							XnStatus status = users.getXnUserGenerator().GetSkeletonCap().LoadCalibrationData(user->id,dancer);
							users.startTracking(user->id);
							dancers[dancer].userId = user->id;
							if(!status){
								dancers[dancer].state = 2;
							}
						}						
					}
				}
			}
			
			//------
			//Calibrated user
			if(vusers[i]->is_tracked){
				bool matchingUser = NO;
				for(int j=0;j<3;j++){
					if(vusers[i]->id == dancers[j].userId){
						matchingUser = YES;
						dancerFound[j] = true;
					}
				}
				if(!matchingUser)
					numberNonstoredUsers++;
			}
			
			
			//			printf("User %i: Is Calibrating %i, is tracking %i \n",i, vusers[i]->is_calibrating, vusers[i]->is_tracked);
			//	printf("User %i:  \n",i);
		}
		
		//------
		//Update gui
		
		for(int j=0;j<3;j++){
			NSTextField * label;
			switch (j) {
				case 0:
					label = labelA;
					break;
				case 1:
					label = labelB;
					break;
				case 2:
					label = labelC;
					break;						
				default:
					break;
			}
			
			if(dancerFound[j] && dancers[j].state > 0){
				dancerFound[j] = true;
				dispatch_async(dispatch_get_main_queue(), ^{
					[label setStringValue:@"Tracking"];
				});
				dancers[j].state = 2;
			} else if(dancers[j].state > 0){
				dispatch_async(dispatch_get_main_queue(), ^{
					[label setStringValue:@"Searching"];	
				});
				dancers[j].state = 1;
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[label setStringValue:@"No calibration!"];	
				});
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{			
			if(numberNonstoredUsers == 1){
				[storeA setEnabled:true];
				[storeB setEnabled:true];
				[storeC setEnabled:true];
			} else {
				[storeA setEnabled:false];	
				[storeB setEnabled:false];	
				[storeC setEnabled:false];	
			}
		});
	}
}

-(void) draw:(NSDictionary *)drawingInformation{
	if([drawCalibration state]){
		ApplySurface(@"Floor");
		
		ofxPoint2f projHandles[3];	
		projHandles[0] = [self projPoint:0];
		projHandles[1] = [self projPoint:1];
		projHandles[2] = [self projPoint:2];
		
		ofFill();
		//Y Axis 
		ofSetColor(0, 255, 0);
		ofCircle(projHandles[0].x,projHandles[0].y, 10/640.0);
		
		//X Axis
		ofSetColor(255, 0, 0);
		ofCircle(projHandles[1].x,projHandles[1].y, 10/640.0);
		ofLine(projHandles[0].x, projHandles[0].y, projHandles[1].x, projHandles[1].y);
		
		//Z Axis
		ofSetColor(0, 0, 255);
		ofCircle(projHandles[2].x,projHandles[2].y, 10/640.0);
		ofLine(projHandles[0].x, projHandles[0].y, projHandles[2].x, projHandles[2].y);
		
		
		
		for(PersistentBlob * b in persistentBlobs){
			/*	ofxPoint3f o = ofxPoint3f([b centroidFiltered].x*640, [b centroidFiltered].y*480, [b avgDepth]);
			 cout<<o.x<<"  "<<o.y<<"  "<<o.z<<endl;
			 ofxPoint3f foot = [self convertKinectToWorld:o];
			 ofxPoint3f wfoot = [self convertWorldToFloor:foot];
			 */	
			ofxPoint3f p = [b centroidFiltered];
			
			ofSetLineWidth(1);
			ofFill();
			ofSetColor(255, 255, 255);
			ofNoFill();
			ofCircle(p.x, p.z, 10.0/640);
			
			ofFill();
			ofSetColor(255, 255, 255,255*(1-p.y/300.0));
			ofCircle(p.x, p.z, 10.0/640);
			
			//			cout<<wfoot.x<<"  "<<wfoot.z<<endl;
			
		}
		
		ofxPoint3f kinect = [self convertWorldToFloor:ofxPoint3f(0,0,0)];
		
		ofxPoint3f lfoot, rfoot, lhand, rhand;
		if(users.getTrackedUsers().size() > 0){
			ofxTrackedUser * user = users.getTrackedUser(0);
			lfoot = [self convertWorldToFloor:user->left_lower_leg.worldEnd];
			rfoot = [self convertWorldToFloor:user->right_lower_leg.worldEnd];
			lhand = [self convertWorldToFloor:user->left_lower_arm.worldEnd];
			rhand = [self convertWorldToFloor:user->right_lower_arm.worldEnd];
			
		}
		
		{
			ofxPoint3f border0,border1, border2, border3;
			xn::DepthMetaData dmd;
			depth.getXnDepthGenerator().GetMetaData(dmd);
			
			XnPoint3D pIn[3];
			pIn[0].X = 0;
			pIn[0].Y = 240;
			pIn[0].Z = 4200;
			pIn[1].X = 320;
			pIn[1].Y = 240;
			pIn[1].Z = 4200;
			pIn[2].X = 640;
			pIn[2].Y = 240;
			pIn[2].Z = 4200;
			
			XnPoint3D pOut[3];				
			depth.getXnDepthGenerator().ConvertProjectiveToRealWorld(3, pIn, pOut);
			border0 = [self convertWorldToFloor:ofxPoint3f(0,0,0)];
			border1 = [self convertWorldToFloor:ofxPoint3f(pOut[0].X, pOut[0].Y, pOut[0].Z)];;
			border2 = [self convertWorldToFloor:ofxPoint3f(pOut[1].X, pOut[1].Y, pOut[1].Z)];
			border3 = [self convertWorldToFloor:ofxPoint3f(pOut[2].X, pOut[2].Y, pOut[2].Z)];
			
			ofSetColor(255, 0, 0);
			glBegin(GL_LINE_STRIP);
			glVertex2d(border0.x, border0.z);
			glVertex2d(border1.x, border1.z);
			glVertex2d(border2.x, border2.z);
			glVertex2d(border3.x, border3.z);
			glVertex2d(border0.x, border0.z);
			glEnd();
		}
		
		ofSetLineWidth(1);
		ofFill();
		ofSetColor(255, 255, 0);
		ofCircle(kinect.x, kinect.z, 10.0/640);
		
		ofEnableAlphaBlending();
		ofNoFill();
		ofSetColor(0, 255, 0, 255);
		ofCircle(lfoot.x, lfoot.z, 15.0/640);
		ofFill();
		ofSetColor(0, 255, 0, 255*(1-lfoot.y/500.0));
		ofCircle(lfoot.x, lfoot.z, 15.0/640);
		
		ofNoFill();
		ofSetColor(255, 0, 0, 255);
		ofCircle(rfoot.x, rfoot.z, 15.0/640);
		ofFill();
		ofSetColor(255, 0, 0, 255*(1-rfoot.y/500.0));
		ofCircle(rfoot.x, rfoot.z, 15.0/640);
		
		ofNoFill();
		ofSetColor(255, 255, 0, 255);
		ofCircle(lhand.x, lhand.z, 15.0/640);
		ofFill();
		ofSetColor(255, 255, 0, 255*(1-lhand.y/500.0));
		ofCircle(lhand.x, lhand.z, 15.0/640);
		
		
		ofNoFill();
		ofSetColor(0, 255, 244, 255);
		ofCircle(rhand.x, rhand.z, 15.0/640);
		ofFill();
		ofSetColor(0, 255, 255, 255*(1-rhand.y/500.0));
		ofCircle(rhand.x, rhand.z, 15.0/640);
		
		
		PopSurface();
	}
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	ofBackground(0, 0, 0);
	
	if(!kinectConnected){
		ofSetColor(255, 255, 255);
		ofDrawBitmapString("Kinect not connected", 640/2-80, 480/2-8);
	} else {
		ofEnableAlphaBlending();
		
		if([openglTabView indexOfTabViewItem:[openglTabView selectedTabViewItem]] == 0){
			ofxPoint3f points[3];
			ofxPoint2f handles[3];
			ofxPoint2f projHandles[3];
			
			points[0] = [self point3:0];
			points[1] = [self point3:1];
			points[2] = [self point3:2];
			
			handles[0] = [self point2:0];
			handles[1] = [self point2:1];
			handles[2] = [self point2:2];
			
			projHandles[0] = [self projPoint:0];
			projHandles[1] = [self projPoint:1];
			projHandles[2] = [self projPoint:2];
			
			
			
			//----------
			//Depth image	
			
			glPushMatrix();{
				glScaled(0.5, 0.5, 1.0);
				depth.draw();
			}glPopMatrix();
			
			
			glPushMatrix();{
				glTranslated(0, 0, 0);
				glScaled((640/2), (480/2), 1);
				
				ofNoFill();
				//Y Axis 
				ofSetColor(0, 255, 0);
				ofCircle(handles[0].x,handles[0].y, 10/640.0);
				
				//X Axis
				ofSetColor(255, 0, 0);
				ofCircle(handles[1].x,handles[1].y, 10/640.0);
				ofLine(handles[0].x, handles[0].y, handles[1].x, handles[1].y);
				
				//Z Axis
				ofSetColor(0, 0, 255);
				ofCircle(handles[2].x,handles[2].y, 10/640.0);
				ofLine(handles[0].x, handles[0].y, handles[2].x, handles[2].y);
			}glPopMatrix();
			ofSetColor(255, 255, 255);
			ofDrawBitmapString("Depthimage", 10, 10);
			
			
			//----------
			//Top view
			glPushMatrix();{
				glTranslated((640/2), 0, 0);
				glScaled((640/2), (480/2), 1);
				
				glTranslated(0.5, 0, 0);
				glScaled(1.0/4000.0, 1.0/4000.0, 1);
				
				ofFill();
				//Y Axis 
				ofSetColor(0, 255, 0);
				ofCircle(points[0].x,points[0].z, 2000*10/640.0);
				
				//X Axis
				ofSetColor(255, 0, 0);
				ofCircle(points[1].x,points[1].z, 2000*10/640.0);
				ofLine(points[0].x, points[0].z, points[1].x, points[1].z);
				
				//Z Axis
				ofSetColor(0, 0, 255);
				ofCircle(points[2].x,points[2].z, 2000*10/640.0);
				ofLine(points[0].x, points[0].z, points[2].x, points[2].z);
				
			}glPopMatrix();
			ofSetColor(255, 255, 255);
			ofDrawBitmapString("TOP - Kinect world", (640/2)+10, 10);
			
			//----------
			//Projectionview
			glPushMatrix();{
				glTranslated(0, 480/2, 0);
				glScaled((640/2), (480/2), 1);
				glScaled(640/480, 1, 1);
				glTranslated(0.5, 0.5, 0);
				
				float aspect = [self floorAspect];
				ofFill();
				ofSetColor(70, 70, 70);
				if(aspect < 1){
					glTranslated(-aspect/2, -0.5, 0);
				} else {
					glTranslated(-0.5, -(1.0/aspect)/2.0, 0);
					glScaled(1.0/aspect, 1.0/aspect, 1);
				}
				
				ofRect(0,0,aspect, 1);
				ofNoFill();
				ofSetColor(120, 120, 120);
				ofRect(0,0,aspect, 1);
				
				ofFill();
				//Y Axis 
				ofSetColor(0, 255, 0);
				ofCircle(projHandles[0].x,projHandles[0].y, 10/640.0);
				
				//X Axis
				ofSetColor(255, 0, 0);
				ofCircle(projHandles[1].x,projHandles[1].y, 10/640.0);
				ofLine(projHandles[0].x, projHandles[0].y, projHandles[1].x, projHandles[1].y);
				
				//Z Axis
				ofSetColor(0, 0, 255);
				ofNoFill();
				ofCircle(projHandles[2].x,projHandles[2].y, 10/640.0);
				ofLine(projHandles[0].x, projHandles[0].y, projHandles[2].x, projHandles[2].y);
				
				
			}glPopMatrix();
			ofSetColor(255, 255, 255);
			ofDrawBitmapString("TOP - Floorspace", 10, 480/2+10);
			
			//----------	
			//Mixed view
			glPushMatrix();{
				glTranslated(640/2, 480/2, 0);	
				glScaled((640/2), (480/2), 1);
				glScaled(640/480, 1, 1);
				glTranslated(0.5, 0.5, 0);
				
				float aspect = [self floorAspect];
				ofFill();
				ofSetColor(70, 70, 70);
				if(aspect < 1){
					glTranslated(-aspect/2, -0.5, 0);
				} else {
					glTranslated(-0.5, -(1.0/aspect)/2.0, 0);
					glScaled(1.0/aspect, 1.0/aspect, 1);
				}
				
				ofRect(0,0,aspect, 1);
				ofNoFill();
				ofSetColor(120, 120, 120);
				ofRect(0,0,aspect, 1);
				
				ofxPoint3f kinect = [self convertWorldToFloor:ofxPoint3f(0,0,0)];
				ofxPoint3f p1 = [self convertWorldToFloor:points[0]];		
				ofxPoint3f p2 = [self convertWorldToFloor:points[1]];		
				ofxPoint3f p3 = [self convertWorldToFloor:points[2]];		
				
				ofxPoint3f lfoot, rfoot, lhand, rhand;
				if(users.getTrackedUsers().size() > 0){
					ofxTrackedUser * user = users.getTrackedUser(0);
					lfoot = [self convertWorldToFloor:user->left_lower_leg.worldEnd];
					rfoot = [self convertWorldToFloor:user->right_lower_leg.worldEnd];
					lhand = [self convertWorldToFloor:user->left_lower_arm.worldEnd];
					rhand = [self convertWorldToFloor:user->right_lower_arm.worldEnd];
					
				}
				
				{
					ofxPoint3f border0,border1, border2, border3;
					xn::DepthMetaData dmd;
					depth.getXnDepthGenerator().GetMetaData(dmd);
					
					XnPoint3D pIn[3];
					pIn[0].X = 0;
					pIn[0].Y = 240;
					pIn[0].Z = 4200;
					pIn[1].X = 320;
					pIn[1].Y = 240;
					pIn[1].Z = 4200;
					pIn[2].X = 640;
					pIn[2].Y = 240;
					pIn[2].Z = 4200;
					
					XnPoint3D pOut[3];				
					depth.getXnDepthGenerator().ConvertProjectiveToRealWorld(3, pIn, pOut);
					border0 = [self convertWorldToFloor:ofxPoint3f(0,0,0)];
					border1 = [self convertWorldToFloor:ofxPoint3f(pOut[0].X, pOut[0].Y, pOut[0].Z)];;
					border2 = [self convertWorldToFloor:ofxPoint3f(pOut[1].X, pOut[1].Y, pOut[1].Z)];
					border3 = [self convertWorldToFloor:ofxPoint3f(pOut[2].X, pOut[2].Y, pOut[2].Z)];
					
					ofSetColor(255, 0, 0);
					glBegin(GL_LINE_STRIP);
					glVertex2d(border0.x, border0.z);
					glVertex2d(border1.x, border1.z);
					glVertex2d(border2.x, border2.z);
					glVertex2d(border3.x, border3.z);
					glVertex2d(border0.x, border0.z);
					glEnd();
				}
				
				
				ofSetLineWidth(1);
				ofFill();
				ofSetColor(255, 255, 0);
				ofCircle(kinect.x, kinect.z, 10.0/640);
				ofSetColor(0, 255, 0);
				ofCircle(p1.x, p1.z, 10.0/640);
				ofSetColor(255, 0, 0);
				ofCircle(p2.x, p2.z, 10.0/640);
				ofSetColor(0, 0, 255);
				ofCircle(p3.x, p3.z, 10.0/640);
				
				ofEnableAlphaBlending();
				ofNoFill();
				ofSetColor(0, 255, 0, 255);
				ofCircle(lfoot.x, lfoot.z, 15.0/640);
				ofFill();
				ofSetColor(0, 255, 0, 255*(1-lfoot.y/500.0));
				ofCircle(lfoot.x, lfoot.z, 15.0/640);
				
				ofNoFill();
				ofSetColor(255, 0, 0, 255);
				ofCircle(rfoot.x, rfoot.z, 15.0/640);
				ofFill();
				ofSetColor(255, 0, 0, 255*(1-rfoot.y/500.0));
				ofCircle(rfoot.x, rfoot.z, 15.0/640);
				
				ofNoFill();
				ofSetColor(255, 255, 0, 255);
				ofCircle(lhand.x, lhand.z, 15.0/640);
				ofFill();
				ofSetColor(255, 255, 0, 255*(1-lhand.y/500.0));
				ofCircle(lhand.x, lhand.z, 15.0/640);
				
				
				ofNoFill();
				ofSetColor(0, 255, 244, 255);
				ofCircle(rhand.x, rhand.z, 15.0/640);
				ofFill();
				ofSetColor(0, 255, 255, 255*(1-rhand.y/500.0));
				ofCircle(rhand.x, rhand.z, 15.0/640);
				
				
				
			}glPopMatrix();
			ofSetColor(255, 255, 255);
			ofDrawBitmapString("TOP - Mixed world", 640/2+10, 480/2+10);
			
			
			ofSetColor(255, 255, 255);
			ofLine((640/2), 0, (640/2), 480);
			ofLine(0, (480/2), 640, (480/2));	
			
		} else {
			//----------
			//Blob segment view	
			glPushMatrix();{
				glTranslated(0, 0, 0);
				
				int c = NUM_SEGMENTS/2.0;
				for(int i=0;i<c;i++){
					ofSetColor(200, 255, 200);
					grayImage[i]->draw(i*640/c,0,640/c,480/c);
					
					ofSetColor(255, 255, 255);
					ofLine(i*640/c, 0, i*640/c, 480/c);
					if(distanceNear[i] > 0)
						ofDrawBitmapString("Segment "+ofToString(i)+"\n "+ofToString(distanceNear[i])+" - "+ofToString(distanceFar[i]), i*640/c+5, 10);
				}
				glTranslated(0, 480/c, 0);
				for(int i=c;i<c*2;i++){
					ofSetColor(200, 255, 200);
					grayImage[i]->draw((i-c)*640/c,0,640/c,480/c);
					
					ofSetColor(255, 255, 255);
					ofLine((i-c)*640/c, 0, (i-c)*640/c, 480/c);
					if(distanceNear[i] > 0)
						ofDrawBitmapString("Segment "+ofToString(i)+"\n "+ofToString(distanceNear[i])+" - "+ofToString(distanceFar[i]), (i-c)*640/c+5, 10);
					
				}
				ofLine(0, 0, 640, 0);
				ofLine(0, 480/c, 640, 480/c);
				ofLine(0, 480/c*2, 640, 2*480/c);
				
			}glPopMatrix();	
			
			
			//----------
			//Heat view
			glPushMatrix();{
				glTranslated(0, 480-30, 0);
				glBegin(GL_LINES);
				for(int i=0;i<1000;i++){
					glColor3f(threadHeatMap[i]*20, threadHeatMap[i]*20, threadHeatMap[i]*20);
					glVertex3d(640.0*i/1000.0, 0, 0);
					glVertex3d(640.0*i/1000.0, 20, 0);
				}
				glEnd();
				
				glBegin(GL_LINES);
				for(int i=0;i<NUM_SEGMENTS;i++){
					if(distanceNear[i] > 0){
						switch (i) {
							case 0:
								ofSetColor(255, 0, 0);
								break;
							case 1:
								ofSetColor(0, 255, 0);
								break;
							case 2:
								ofSetColor(0, 0, 255);
								break;
							case 3:
								ofSetColor(255, 255, 0);
								break;
							case 4:
								ofSetColor(255, 0, 255);
								break;
							default:
								break;
						}
						
						//glColor3f(threadHeatMap[i]*20, threadHeatMap[i]*20, threadHeatMap[i]*20);
						glVertex3d(640.0*distanceNear[i]/10000, 0, 0);
						glVertex3d(640.0*distanceNear[i]/10000, 20, 0);
						glVertex3d(640.0*distanceFar[i]/10000, 0, 0);
						glVertex3d(640.0*distanceFar[i]/10000, 20, 0);
						
					}
				}
				glEnd();
				
				glBegin(GL_LINES);
				Blob * b;
				for(b in blobs){
					switch ([b segment]) {
						case 0:
							ofSetColor(255, 0, 0);
							break;
						case 1:
							ofSetColor(0, 255, 0);
							break;
						case 2:
							ofSetColor(0, 0, 255);
							break;
						case 3:
							ofSetColor(255, 255, 0);
							break;
						case 4:
							ofSetColor(255, 0, 255);
							break;
						default:
							break;
					}
					glVertex3d(640.0*[b avgDepth]/10000, 0, 0);
					glVertex3d(640.0*[b avgDepth]/10000, 30, 0);
					
				}
				glEnd();
				
				
			} glPopMatrix();
			
			
			//----------
			//Blob view
			glPushMatrix();{
				glTranslated(0, 480, 0);
				
				glPushMatrix();
				glScaled(0.5, 0.5, 1.0);
				users.draw();
				glPopMatrix();
				/*
				 Blob * b;
				 for(b in blobs){
				 switch ([b segment]) {
				 case 0:
				 ofSetColor(255, 0, 0);
				 break;
				 case 1:
				 ofSetColor(0, 255, 0);
				 break;
				 case 2:
				 ofSetColor(0, 0, 255);
				 break;
				 case 3:
				 ofSetColor(255, 255, 0);
				 break;
				 case 4:
				 ofSetColor(255, 0, 255);
				 break;
				 default:
				 break;
				 }
				 glBegin(GL_LINE_STRIP);
				 for(int i=0;i<[b nPts];i++){
				 ofxVec2f p = [b pts][i];
				 //				p = [GetPlugin(ProjectionSurfaces) convertPoint:[b pts][i] fromProjection:"Front" surface:"Floor"];
				 p = [b originalblob]->pts[i];
				 glVertex2f(p.x*320, p.y*240);
				 
				 //glVertex2f(w*3+p.x/640.0*w, p.y/480.0*h);
				 //cout<<p.x<<"  "<<p.y<<endl;
				 
				 }
				 glEnd();
				 }*/
				PersistentBlob * blob;				
				for(blob in persistentBlobs){
					int i=blob->pid%5;
					switch (i) {
						case 0:
							ofSetColor(255, 0, 0,255);
							break;
						case 1:
							ofSetColor(0, 255, 0,255);
							break;
						case 2:
							ofSetColor(0, 0, 255,255);
							break;
						case 3:
							ofSetColor(255, 255, 0,255);
							break;
						case 4:
							ofSetColor(0, 255, 255,255);
							break;
						case 5:
							ofSetColor(255, 0, 255,255);
							break;
							
						default:
							ofSetColor(255, 255, 255,255);
							break;
					}
					Blob * b;
					for(b in [blob blobs]){
						glBegin(GL_LINE_STRIP);
						for(int i=0;i<[b nPts];i++){
							ofxVec2f p = [b pts][i];
							//				p = [GetPlugin(ProjectionSurfaces) convertPoint:[b pts][i] fromProjection:"Front" surface:"Floor"];
							p = [b originalblob]->pts[i];
							glVertex2f(320*p.x, 240*p.y);
							
							//glVertex2f(w*3+p.x/640.0*w, p.y/480.0*h);
							//cout<<p.x<<"  "<<p.y<<endl;
							
						}
						glEnd();
					}
				}
				
			}glPopMatrix();	
		}
	}
}

-(vector<ofxPoint3f>) getPointsInBoxXMin:(float)xMin xMax:(float)xMax yMin:(float)yMin yMax:(float)yMax zMin:(float)zMin zMax:(float)zMax res:(int)res{
	vector<ofxPoint3f> points;
	
	if(kinectConnected){
		xn::DepthMetaData dmd;
		depth.getXnDepthGenerator().GetMetaData(dmd);	
		const XnDepthPixel* pixels = dmd.Data();
		
		
		for(int i=0;i<640*480;i+=res){
			int x = i % 640;
			int y = floor(i / 640);
			if(pixels[i] > 0){
				ofxPoint3f p = [self convertWorldToFloor:[self convertKinectToWorld:ofxPoint3f(x,y, pixels[i])]];
				if(p.x > xMin && p.x < xMax && p.y > yMin && p.y < yMax && p.z > zMin && p.z < zMax){
					points.push_back(p);
				}
			}
		}
		
	}
	return points;	
	
}

-(void) calculateMatrix{
	ofxVec2f v1, v2, v3;
	ofxPoint3f points[3];
	ofxPoint2f projHandles[3];
	
	points[0] = [self point3:0];
	points[1] = [self point3:1];
	points[2] = [self point3:2];
	
	projHandles[0] = [self projPoint:0];
	projHandles[1] = [self projPoint:1];
	projHandles[2] = [self projPoint:2];	
	
	//Angle 1 er y akse rotation. Vinklen mellem de to blå akser (2)
	v1 = ofxVec2f((points[2]-points[0]).x,(points[2]-points[0]).z);
	v2 = -ofxVec2f((projHandles[2]-projHandles[0]).x,(projHandles[2]-projHandles[0]).y);	
	v3 = ofxVec2f(0,-1);	
	float angle1 = +v1.angle(v3) + v2.angle(v3);
	
	
	//Angle 3 er z akse rotation. Den er fastdefineret i gulvspace
	v1 = ofxVec2f((points[2]-points[0]).z,(points[2]-points[0]).y);
	v2 = ofxVec2f(-1,0);	
	float angle3 = v1.angle(v2);
	
	[Prop(@"angle1") setFloatValue:angle1];
	[Prop(@"angle3") setFloatValue:angle3];
	
	rotationMatrix.makeRotationMatrix( PropF(@"angle1")*DEG_TO_RAD, ofxVec3f(0,1,0),
									  0, ofxVec3f(0,0,1),
									  PropF(@"angle3")*DEG_TO_RAD, ofxVec3f(1,0,0));
	
	//Angle 2 er x akse rotation. Rød akse (transformeret)
	ofxVec3f v = (points[1]-points[0]);
	v = rotationMatrix.transform3x3(rotationMatrix,v);
	v1 = ofxVec2f((v).x,(v).y);
	
	v2 = ofxVec2f(1,0);	
	v3 = ofxVec2f((projHandles[1]-projHandles[0]).x,(projHandles[1]-projHandles[0]).y);	
	float angle2 = v1.angle(v2);	
	
	[Prop(@"angle2") setFloatValue:angle2];
	
	rotationMatrix.makeRotationMatrix( PropF(@"angle1")*DEG_TO_RAD, ofxVec3f(0,1,0),
									  -PropF(@"angle2")*DEG_TO_RAD, ofxVec3f(0,0,1),
									  PropF(@"angle3")*DEG_TO_RAD, ofxVec3f(1,0,0));
	scale = 1.0/(points[1]-points[0]).length() ;
	
}

-(ofxPoint3f) convertKinectToWorld:(ofxPoint3f)p{
	if(!stop){
		XnPoint3D pIn;
		pIn.X = p.x;
		pIn.Y = p.y;
		pIn.Z = p.z;
		XnPoint3D pOut;
		
		depth.getXnDepthGenerator().ConvertProjectiveToRealWorld(1, &pIn, &pOut);
		
		return ofxPoint3f(pOut.X, pOut.Y, pOut.Z);
	} else {
		return nil;
	}
	
	
}

-(ofxPoint3f) convertWorldToFloor:(ofxPoint3f) p{
	p -= [self point3:0];	
	
	p = rotationMatrix.transform3x3(rotationMatrix,p);
	
	p.z *= -scale*([self projPoint:0] - [self projPoint:2]).length();
	p.x *= scale*([self projPoint:0] - [self projPoint:2]).length();
	//p.y *= scale*([self projPoint:0] - [self projPoint:2]).length();
	
	p += ofxPoint3f([self projPoint:0].x, 0, [self projPoint:0].y);
	
	return p;
}

-(ofxPoint3f) convertWorldToProjection:(ofxPoint3f) p{
	ofxPoint2f p2 = [self convertWorldToFloor:p];
	return [([GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0]) convertToProjection:p2];
}


-(ofxTrackedUser*) getDancer:(int)d{
	ofxTrackedUser* u = users.getUserWithId(dancers[d].userId);
	if(u != nil){
		return u;
	}
	return nil;	
}

-(IBAction) storeCalibration:(id)sender{
	int dancer;
	if(sender == storeA){
		dancer = 0;
	}
	if(sender == storeB){
		dancer = 1;
	}
	if(sender == storeC){
		dancer = 2;
	}
	
	vector<ofxTrackedUser*> vusers = users.getTrackedUsers(); 			
	for(int i=0;i<vusers.size();i++){
		bool matchingUser = NO;
		for(int j=0;j<3;j++){
			if(vusers[i]->id == dancers[j].userId){
				matchingUser = YES;
			}
		}
		if(!matchingUser){
			ofxTrackedUser * user = vusers[i];
			if(user->is_tracked){
				NSLog(@"Store calibration");
				XnStatus status = users.getXnUserGenerator().GetSkeletonCap().SaveCalibrationData(user->id,dancer);
				dancers[dancer].state = 2;
				dancers[dancer].userId = user->id;
			}
			break;	
		}
	}
	
	
	
}
 
-(void) controlMouseDragged:(float)x y:(float)y button:(int)button{
	if(draggedPoint != -1){
		ofxPoint2f mouse = ofPoint(2*x/640.0,2*y/480.0);
		
		if(draggedPoint <= 2){			
			xn::DepthMetaData dmd;
			depth.getXnDepthGenerator().GetMetaData(dmd);
			
			XnPoint3D pIn;
			pIn.X = mouse.x*640;
			pIn.Y = mouse.y*480;
			pIn.Z = dmd.Data()[(int)pIn.X+(int)pIn.Y*640];
			XnPoint3D pOut;
			
			depth.getXnDepthGenerator().ConvertProjectiveToRealWorld(1, &pIn, &pOut);
			ofxPoint3f coord = ofxPoint3f(pOut.X, pOut.Y, pOut.Z);
			[self setPoint3:draggedPoint coord:coord];
			[self setPoint2:draggedPoint coord:mouse];
		} else {
			mouse.y -= 1;
			float aspect = [self floorAspect];
			if(aspect < 1){
				mouse.x -= 0.5;
				mouse.x += aspect/2.0;
			} else {
				mouse.y -= 0.5;
				mouse.y += (1.0/aspect)/2.0;
				mouse *= 1.0/aspect;
			}
			
			[self setProjPoint:draggedPoint-3 coord:mouse];
			
			if(draggedPoint-3 <= 1){
				ofxVec2f v = [self projPoint:1] - [self projPoint:0];
				v = ofxVec2f(-v.y,v.x);
				
				[self setProjPoint:2 coord:[self projPoint:0]+v];
			}
		}
	}
	[self calculateMatrix];
}

-(void) controlMousePressed:(float)x y:(float)y button:(int)button{
	ofxPoint2f mouse = ofPoint(2*x/640,2*y/480);
	draggedPoint = -1;
	if(mouse.y <= 1){
		for(int i=0;i<3;i++){
			if (mouse.distance([self point2:i]) < 0.035) {
				draggedPoint = i;
			}
		}
	} else {
		mouse.y -= 1;	
		float aspect = [self floorAspect];
		if(aspect < 1){
			mouse.x -= 0.5;
			mouse.x += aspect/2.0;
		} else {
			mouse.y -= 0.5;
			mouse.y += (1.0/aspect)/2.0;
			mouse *= 1.0/aspect;
		}
		
		for(int i=0;i<2;i++){
			if (mouse.distance([self projPoint:i]) < 0.035) {
				draggedPoint = i+3;
			}
		}
	}
	xn::DepthMetaData dmd;
	depth.getXnDepthGenerator().GetMetaData(dmd);
	
	XnPoint3D pIn;
	pIn.X = mouse.x*640;
	pIn.Y = mouse.y*480;
	
	
	NSLog(@"Mouse pressed %i  mouse: %fx%f   distance: %i",draggedPoint, mouse.x, mouse.y,dmd.Data()[(int)pIn.X+(int)pIn.Y*640]);
}

-(void) controlMouseReleased:(float)x y:(float)y{
	draggedPoint = -1;
}

-(float) floorAspect{
	return 	[[([GetPlugin(Keystoner) getSurface:@"Floor" viewNumber:0 projectorNumber:0]) aspect] floatValue];
}


-(ofxPoint3f) point3:(int)point{
//	if(point3Cache[point] == nil)
		point3Cache[point] = ofxPoint3f([[customProperties valueForKey:[NSString stringWithFormat:@"point%ix",point]] floatValue], [[customProperties valueForKey:[NSString stringWithFormat:@"point%iy",point]] floatValue], [[customProperties valueForKey:[NSString stringWithFormat:@"point%iz",point]] floatValue]);
	
	return point3Cache[point];	
}
-(ofxPoint2f) point2:(int)point{
//	if(point2Cache[point] == nil)
		point2Cache[point] = ofxPoint2f([[customProperties valueForKey:[NSString stringWithFormat:@"point%ia",point]] floatValue], [[customProperties valueForKey:[NSString stringWithFormat:@"point%ib",point]] floatValue]);

	return point2Cache[point];
}
-(ofxPoint2f) projPoint:(int)point{
//	if(projPointCache[point] == nil)
		projPointCache[point] = ofxPoint2f([[customProperties valueForKey:[NSString stringWithFormat:@"proj%ix",point]] floatValue], [[customProperties valueForKey:[NSString stringWithFormat:@"proj%iy",point]] floatValue]);
	return projPointCache[point];
}

-(void) setPoint3:(int) point coord:(ofxPoint3f)coord{
	[customProperties setValue:[NSNumber numberWithFloat:coord.x] forKey:[NSString stringWithFormat:@"point%ix",point]];
	[customProperties setValue:[NSNumber numberWithFloat:coord.y] forKey:[NSString stringWithFormat:@"point%iy",point]];
	[customProperties setValue:[NSNumber numberWithFloat:coord.z] forKey:[NSString stringWithFormat:@"point%iz",point]];
	point3Cache[point] = nil;
}
-(void) setPoint2:(int) point coord:(ofxPoint2f)coord{
	[customProperties setValue:[NSNumber numberWithFloat:coord.x] forKey:[NSString stringWithFormat:@"point%ia",point]];
	[customProperties setValue:[NSNumber numberWithFloat:coord.y] forKey:[NSString stringWithFormat:@"point%ib",point]];
		point2Cache[point] = nil;
}
-(void) setProjPoint:(int) point coord:(ofxPoint2f)coord{
	[customProperties setValue:[NSNumber numberWithFloat:coord.x] forKey:[NSString stringWithFormat:@"proj%ix",point]];
	[customProperties setValue:[NSNumber numberWithFloat:coord.y] forKey:[NSString stringWithFormat:@"proj%iy",point]];
	projPointCache[point] = nil;
}

-(ofxUserGenerator*) getUserGenerator{
	return &users;	
}

-(void) applicationWillTerminate:(NSNotification *)note{
	stop = true;
	context.getXnContext().Shutdown();
}

//-----
// Blob tracking - the hard part
//-----
-(void) performBlobTracking:(id)param{
	while(1){		
		pthread_mutex_lock(&mutex);			
		
		if(threadUpdateContour){
			int count = 0;
			int lastSegment = 0;			
			
			int segmentSize = PropI(@"segmentSize");			
			int min = PropI(@"minDistance");
			int max = PropI(@"maxDistance");
			
			int ymin = PropF(@"yMin");
			int ymax = PropF(@"yMax");
			
			[threadBlobs removeAllObjects];
			
			
			
			
			
			for(int i=0;i<1000;i++){
				threadHeatMap[i] = 0;
			}
			
			for(int i=0;i<640*480;i++){	
				int index = threadedPixels[i] / 10.0;
				threadHeatMap[index] ++;
			}
			
			
			for(int i=0;i<1000;i++){
				if(i*10.0 < min || i*10.0 > max)
					threadHeatMap[i] = 0;
			}
			
			while(count < NUM_SEGMENTS){
				if(lastSegment < 9600){
					memset(pixelBufferTmp, 0, 640*480);
					
					int nearestPixel = -1;		
					int start = ceil(lastSegment/10.0)+1;
					for(int i=start;i<1000;i++){							
						if(threadHeatMap[i] > 0 && (nearestPixel == -1)){
							nearestPixel = i*10.0;
							break;
						}
					}
					
					if(nearestPixel != -1){					
						int c = 0;
						//Find s - the size of the segment
						int s = 0;						
						if(nearestPixel > 9000){
							s = 1000;
						} else {							
							int start = ceil(nearestPixel/10.0);
							for(int i=start;i<1000;i++){							
								if(threadHeatMap[i] > 0 && i * 10.0 <= nearestPixel + s + segmentSize){
									s = i*10.0 - nearestPixel;								
								}
							}
						}
						
						if(s > 0){
							for(int i=0;i<640*480;i++){
								if(threadedPixels[i] >= nearestPixel && threadedPixels[i] < nearestPixel + s){
									pixelBufferTmp[i] = 255;
									c++;
								} 
							}	
						}
						lastSegment = nearestPixel+s;
						
						threadGrayImage[count]->setFromPixels(pixelBufferTmp,640,480);			
						if(c > 10){
							contourFinder->findContours(*threadGrayImage[count], 20, (640*480)/10, 10, false, true);
							
							for(int i=0;i<contourFinder->nBlobs;i++){
								ofxCvBlob * blob = &contourFinder->blobs[i];
								Blob * blobObj = [[[Blob alloc] initWithBlob:blob] autorelease];
								[blobObj setCameraId:0];
								[blobObj normalize:640 height:480];
								[blobObj setSegment:count];
								
								float avg = 0;
								for( int i=0;i<blob->pts.size();i++){
									avg += threadedPixels[int(blob->pts.at(i).y*640 + blob->pts.at(i).x)];
								}
								avg /= (float)blob->pts.size();
								[blobObj setAvgDepth:avg];
								
								ofxPoint2f p = [blobObj getLowestPoint];
								ofxPoint3f p3 = [self convertWorldToFloor:[self convertKinectToWorld:ofxPoint3f(p.x*640,p.y*480,avg)]];
								if(p3.y > ymin && p3.y < ymax){								
									[threadBlobs addObject:blobObj];							
								}
							}
							
							distanceNear[count] = nearestPixel;
							distanceFar[count] = nearestPixel + s;
						} else {
							count --;
						}
						
					} else {
						threadGrayImage[count]->set(0);			
						distanceNear[count] = 0;
					}
				}
				count ++;				
			}		
		}
		
		threadUpdateContour = false;		
		
		pthread_mutex_unlock(&mutex);
		
		[NSThread sleepForTimeInterval:0.01];
	}
}

@end