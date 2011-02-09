#import "Leaking.h"
#import "Kinect.h"
#import "Keystoner.h"


@implementation Leaking

-(void) initPlugin{
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"state"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:10.0] named:@"blur"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"blurStartSpeed"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:2.0] named:@"blurDecreaseSpeed"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:30.0] named:@"circleSize"];	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:10.0] named:@"tmpBlur"];	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:5] named:@"fade"];	
	
	for(int i=0;i<NUMIMAGES;i++){
		[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0 maxValue:100.0] named:[NSString stringWithFormat:@"percentage%i",i]];	
	}
	
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"clear"];
	
	
	mouseh = -1;
}

-(void) setup{
	for(int i=0;i<NUMIMAGES;i++){
		//blobs = [[NSMutableArray array] retain];
		contourFinder[i] = new ofxCvContourFinder();
		
		images[i] = new 	ofxCvFloatImage();
		images[i]->allocate(IMGWIDTH, IMGHEIGHT);
		images[i]->set(0.0);
		cout<<images[i]->getNativeScaleMax()<<endl;
	}
	tmpImage = new 	ofxCvFloatImage();
	tmpImage->allocate(IMGWIDTH, IMGHEIGHT);
	tmpImage->set(0);
	
	curImage = -1;
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"clear") && [object boolValue]){
		clear = true;
		[object setBoolValue:NO];
	}
}


-(void) update:(NSDictionary *)drawingInformation{
	
	if(clear){
		cout<<"Clear"<<endl;
		clear = NO;
		storedPoints.clear();
	}
	
	if(PropI(@"state") == 0){
		vector<CvPoint> tempPoints;
		
		vector<CvPoint> downPoints;
		
		if (mouseh != -1) {	
			CvPoint center;
			center.x = mousex * IMGWIDTH;
			center.y = mousey * IMGHEIGHT;		
			
			if (mouseh == 0) {
				downPoints.push_back(center);
			} else {
				tempPoints.push_back(center);
			}
		}
		
		ofxPoint3f lhand, rhand;
		ofxUserGenerator * users = [GetPlugin(Kinect) getUserGenerator];
		if(users->getTrackedUsers().size() > 0){
			ofxTrackedUser * user = users->getTrackedUser(0);
//			lfoot = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_leg.worldEnd];
//			rfoot = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_leg.worldEnd];
			lhand = [GetPlugin(Kinect) convertWorldToFloor:user->left_lower_arm.worldEnd];
			rhand = [GetPlugin(Kinect) convertWorldToFloor:user->right_lower_arm.worldEnd];	
			
			CvPoint lpoint;
			lpoint.x = lhand.x * 1.0/Aspect(@"Floor",0)*IMGWIDTH;
			lpoint.y = lhand.z * IMGHEIGHT;

			CvPoint rpoint;
			rpoint.x = rhand.x * 1.0/Aspect(@"Floor",0)*IMGWIDTH;
			rpoint.y = rhand.z * IMGHEIGHT;
			
			if(lhand.y < 100){
				downPoints.push_back(lpoint);
			} else {
				tempPoints.push_back(lpoint);				
			}
			
			if(rhand.y < 100){
				downPoints.push_back(rpoint);
			} else {
				tempPoints.push_back(rpoint);				
			}
		}
			
			
		
		//De faste images skal tegnes op
		if(downPoints.size() > 0){
			if(imageSelected){
				for(int i=0;i<downPoints.size();i++){
					cvCircle(images[curImage]->getCvImage(), downPoints[i], PropF(@"circleSize"), cvScalar(1.0, 1.0, 1.0, 1.0), -1, 1, 1);			
				}
				images[curImage]->flagImageChanged();
				timeoutCounter[curImage] = 0;
				blurSpeed[curImage] = PropF(@"blurStartSpeed");
			} else {
				curImage ++;
				if(curImage >= NUMIMAGES)
					curImage = 0;
				timeoutCounter[curImage] = 0;
				imageSelected = YES;
			}
		} else if(imageSelected){
			timeoutCounter[curImage] ++;
			
			if(timeoutCounter[curImage] > 20){
				imageSelected = NO;
			}
		}
		
		//Temp billedet skal tegnes op
		for(int i=0;i<tempPoints.size();i++){
			cvCircle(tmpImage->getCvImage(), tempPoints[i], PropF(@"circleSize"), cvScalar(1.0, 1.0, 1.0, 1.0), -1, 1, 1);			
			tmpImage->flagImageChanged();
			
		}		
	}
	
	/*for(int i=0;i<NUMIMAGES;i++){
	 blurSpeed[i] -= PropF(@"blurDecreaseSpeed")*1.0/ofGetFrameRate();
	 if(blurSpeed[i] < 0){
	 blurSpeed[i] = 0;
	 } 
	 
	 blurCounter[i] += blurSpeed[i];
	 if(blurCounter[i] >= 1){
	 images[i]->blurGaussian(PropI(@"blur"));	
	 blurCounter[i] = 0;
	 }
	 
	 }
	 */
	
	
	if(PropI(@"blur") > 0){
		for(int i=0;i<NUMIMAGES;i++){
			//			images[i]->blur(PropI(@"blur"));
			images[i]->blurGaussian(PropI(@"blur"));
		}
	}
	
	if(PropI(@"tmpBlur") > 0){
		tmpImage->blur(PropI(@"tmpBlur"));
	}
	
	if(PropF(@"fade")){
		
		*tmpImage -= 1.0*PropF(@"fade")/100.0;	
	}
	
	//Træk current image fra de andre
	for(int i=0;i<NUMIMAGES;i++){
		for(int y=i+1;y<NUMIMAGES;y++){
			if(y != i){
				//				cvSub(images[y]->getCvImage()
				for( int ii=0; ii<IMGHEIGHT; ii++ ) {
					float* ptr1 = (float*)(images[y]->getCvImage()->imageData + (int)(ii)*images[y]->getCvImage()->widthStep);
					float* ptr2 = (float*)(images[i]->getCvImage()->imageData + (int)(ii)*images[i]->getCvImage()->widthStep);
					
					for( int j=0; j<IMGWIDTH; j++ ) {
						if(ptr2[j] > 0 && ptr1[j] > 0){
							ptr1[(int)(j)] -= 0.8*ptr2[j];//ptr[(int)(j)]<0.00001 ? 0 : ptr[(int)(j+roi.x)]*scalar;
							if(ptr1[j] < 0)
								ptr1[j] = 0;
							
							ptr2[(int)(j)] -= 0.8*ptr1[j];//ptr[(int)(j)]<0.00001 ? 0 : ptr[(int)(j+roi.x)]*scalar;
							if(ptr2[j] < 0)
								ptr2[j] = 0;
							
							
						}
						if(ptr2[j] > 1)
							ptr2[j] = 1;
						if(ptr1[j] > 1)
							ptr1[j] = 1;
						
					}
				}
				
				
				///	*images[y] -= *images[i];
				//								*images[y] -=  0.01;
			}
		}
	}
	
	for(int i=0;i<NUMIMAGES;i++){
		//		images[i]->flagImageChanged();
		
		
		float percentageGoal = PropF( ([NSString stringWithFormat:@"percentage%i",i]) ) / 100.0;
		float percentage = [self percentage:i];
		if(percentageGoal > 0){
			//			if(percentageGoal-percentage < -0.05){
			if(percentageGoal < percentage){
				*images[i] += (percentageGoal - percentage)*0.1;	
				//				images[i]->erode();
				//			} else if(percentageGoal-percentage > 0.05){
			} else {
				*images[i] *= 1.0 + (percentageGoal - percentage)*0.3;	
//				*images[i] += (percentageGoal - percentage)*0.1;	
				
				//				images[i]->dilate();
			}
			
			
		} else {
			*images[i] *= 1.001;	
		}
	}
	/*ofxCvGrayscaleImage background;
	 background.allocate(IMGWIDTH, IMGHEIGHT);
	 background.set(1);
	 for(int i=0;i<NUMIMAGES;i++){
	 images[i]->contrastStretch();
	 }*/
	
	for(int i=0;i<NUMIMAGES;i++){
		ofxCvGrayscaleImage smallerImage;
		smallerImage.allocate(IMGWIDTH, IMGHEIGHT);
		smallerImage = *images[i];
		//	smallerImage.threshold(30, false);
		
		contourFinder[i]->findContours(smallerImage, 20, (IMGWIDTH*IMGHEIGHT)/1, 10, false, true);	
	}
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	ofBackground(0, 0, 0);
	ofEnableAlphaBlending();
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	ofSetColor(255, 255, 255);
	
	ApplySurface(@"Floor");
	
	tmpImage->draw(0, 0, Aspect(@"Floor",0),1);
	
	ofNoFill();
	
	for(int i=0;i<NUMIMAGES;i++){
		images[i]->draw(0, 0, Aspect(@"Floor",0),1);	
		
		for(int b=0;b<contourFinder[i]->nBlobs;b++){
			ofBeginShape();	
			for(int p=0;p<contourFinder[i]->blobs[b].nPts;p++){
				ofxPoint2f point = contourFinder[i]->blobs[b].pts[p];
				point.x /= IMGWIDTH;
				point.y /= IMGHEIGHT;
				
				point.x *= Aspect(@"Floor",0);
				point.y *= 1.0;
				
				ofVertex(point.x, point.y);			
			}
			ofEndShape();
		}	
		
		
	}
	PopSurface();
	
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	ofBackground(0, 0, 0);
	ofEnableAlphaBlending();
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	ofSetColor(255, 255, 255);
	
	tmpImage->draw(0, 0, 200,400);
	
	ofNoFill();
	
	for(int i=0;i<NUMIMAGES;i++){
		images[i]->draw(0, 0, 200,400);	
		
		for(int b=0;b<contourFinder[i]->nBlobs;b++){
			ofBeginShape();	
			for(int p=0;p<contourFinder[i]->blobs[b].nPts;p++){
				ofxPoint2f point = contourFinder[i]->blobs[b].pts[p];
				point.x /= IMGWIDTH;
				point.y /= IMGHEIGHT;
				
				point.x *= 200.0;
				point.y *= 400.0;
				
				ofVertex(point.x, point.y);			
			}
			ofEndShape();
		}	
		
		
	}
	
	
	
	
	if(mouseh != -1){
		ofEnableAlphaBlending();
		if(mouseh){
			ofNoFill();
		} else {
			ofFill();
		}
		ofSetColor(255, 255, 0,100);
		ofEllipse(mousex*200.0, mousey*400.0, 15, 15);
	}
	
	
	ofSetColor(255,255, 255);
	glPushMatrix();
	for(int i=0;i<NUMIMAGES;i++){
		glTranslated(0, 15, 0);
		float percentage = [self percentage:i];
		
		ofDrawBitmapString(ofToString(i)+": "+ofToString(percentage*100.0,0)+"%", 5, 10);
	}
	glPopMatrix();
}

-(void) controlMousePressed:(float)x y:(float)y button:(int)button{
	mousex = x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseDragged:(float)x y:(float)y button:(int)button{
	mousex = x / 200.0;
	mousey = y / 400.0;
	mouseh = (controlMouseFlags & NSShiftKeyMask)?0.0:10.0;	
}

-(void) controlMouseReleased:(float)x y:(float)y{
	mouseh = -1;	
}

-(float) percentage:(int)i{
	float percentage = 0;
	
	for(int j=0;j<contourFinder[i]->nBlobs;j++){
		percentage += contourFinder[i]->blobs[j].area;
	}
	
	percentage /= IMGWIDTH*IMGHEIGHT;
	return percentage;	
}

@end
