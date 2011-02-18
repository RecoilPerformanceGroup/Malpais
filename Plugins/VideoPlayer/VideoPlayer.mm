#import "VideoPlayer.h"
#include "Keystoner.h"

@implementation VideoPlayer

@synthesize loadedFiles;

-(void) initPlugin{	
	NSLog(@"Init videplayer");
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:-1 minValue:-1 maxValue:2] named:@"video"];	
	
	lastFramesVideo = 0;
	forceDrawNextFrame = NO;
	
	loadedFiles = [[NSMutableArray array] retain]; 
}

//
//-----
//

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"video")){		
		if(PropI(@"video") < 0){			
			NSLog(@"Reset video");
			dispatch_async(dispatch_get_main_queue(), ^{		
				for(int i=0;i<NUMVIDEOS;i++){				
					if(movie[i]){
						[movie[i] gotoBeginning];				
						[movie[i] setRate:0.0];							
					}
				}
				forceDrawNextFrame = YES;
			});			
		}
	}
}


//
//-----
//


-(IBAction) restart:(id)sender{
	[movie[PropI(@"video")] setCurrentTime:QTMakeTime(0, 60)];	
}

//
//-----
//

- (void) applicationWillTerminate: (NSNotification *)note{
	for(int i=0;i<NUMVIDEOS;i++){
		// stop and release the movie
		if (movie[i]) {
			[movie[i] setRate:0.0];
			SetMovieVisualContext([movie[i] quickTimeMovie], NULL);
			[movie[i] release];
			movie[i] = nil;
		}	
		
		// don't leak textures
		if (currentFrame) {
			CVOpenGLTextureRelease(currentFrame[i]);
			currentFrame[i] = NULL;
		}
		
		// release the OpenGL Texture Context
		if (textureContext[i]) {
			CFRelease(textureContext[i]);
			textureContext[i] = NULL;
		}
	}
}



//
//-----
//

-(BOOL) willDraw:(NSMutableDictionary *)drawingInformation{
	NSLog(@"Will draw?");
	if(PropI(@"video") >= 0 && PropI(@"video") < NUMVIDEOS){
		QTVisualContextTask(textureContext[PropI(@"video")]);
		
		if(forceDrawNextFrame){
			forceDrawNextFrame = NO;
			return YES;
		}
		
		if([movie[int(PropF(@"video"))] rate] != 1){
			dispatch_async(dispatch_get_main_queue(), ^{				
				[movie[int(PropF(@"video"))] setRate:1]; 
			});
		}
		
		const CVTimeStamp * outputTime;
		[[drawingInformation objectForKey:@"outputTime"] getValue:&outputTime];
		if(textureContext[int(PropF(@"video"))] != nil)
			return QTVisualContextIsNewImageAvailable(textureContext[int(PropF(@"video"))], outputTime);
		return NO;	
	} else {
		return NO;	
	}
}

//
//-----
//

-(void) setup{	
	NSLog(@"Setup video");
	[Prop(@"video") setFloatValue:-1];
	dispatch_async(dispatch_get_main_queue(), ^{	
		NSError * error = [NSError alloc];			
		
		NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool:NO], QTMovieOpenAsyncOKAttribute,
									  [NSNumber numberWithBool:NO], QTMovieLoopsAttribute, nil];		
		
		NSString * basePath = [@"~/Movies/DKPerformanceContent" stringByExpandingTildeInPath];
		for(int i=0;i<NUMVIDEOS;i++){
			NSString * fileNumber = [NSString stringWithFormat:@"%i",i+1];
			
			[dict setObject:[NSString stringWithFormat:@"%@/Malpais%@.mov",basePath,fileNumber] forKey:QTMovieFileNameAttribute];
			movie[i] = [[QTMovie alloc] initWithAttributes:dict error:&error];
			if(error != nil){ 
				NSLog(@"ERROR: Could not load movie %i: %@",i,error);
				[dict setObject:[NSString stringWithFormat:@"%@/404.mov",basePath] forKey:QTMovieFileNameAttribute];
				movie[i] = [[QTMovie alloc] initWithAttributes:dict error:&error];		
				
				[loadedFilesController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:i],@"number",
												  @"404.mov",@"name",
												  @"",@"size",
												  @"", @"codec",
												  QTStringFromTime([movie[i] duration]),@"duration",
												  nil]];				
			} else {
				char codecType[5];
				OSType codecTypeNum;
				NSString *codecTypeString = nil;
				
				
				ImageDescriptionHandle videoTrackDescH =(ImageDescriptionHandle)NewHandleClear(sizeof(ImageDescription));				
				
				GetMediaSampleDescription([[[[movie[i] tracks] lastObject] media] quickTimeMedia], 1,
										  (SampleDescriptionHandle)videoTrackDescH);
				bzero(codecType, 5);           
                memcpy((void *)&codecTypeNum, (const void *)&((*(ImageDescriptionHandle)videoTrackDescH)->cType), 4);
                codecTypeNum = EndianU32_LtoB( codecTypeNum );
                memcpy(codecType, (const void*)&codecTypeNum, 4);
                codecTypeString = [NSString stringWithFormat:@"%s", codecType];
				if([codecTypeString isEqualToString:@"jpeg"]){
					codecTypeString = @"JPEG";
				} 
				if([codecTypeString isEqualToString:@"avc1"]){
					codecTypeString = @"H.264";
				} 
				
				[loadedFilesController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:i],@"number",
												  [NSString stringWithFormat:@"Malpais%@.mov",fileNumber],@"name",
												  [NSString stringWithFormat:@"%dx%d",(*(ImageDescriptionHandle)videoTrackDescH)->width,(*(ImageDescriptionHandle)videoTrackDescH)->height],@"size",
												  codecTypeString, @"codec",
												  QTStringFromTime([movie[i] duration]),@"duration",
												  nil]];
				
				NSLog(@"Loaded %@",[NSString stringWithFormat:@"%@/%@.mov",basePath,fileNumber]);
				
				DisposeHandle((Handle)videoTrackDescH);	
			}
			
		}
		
		for(int i=0;i<NUMVIDEOS;i++){
			[movie[i] retain];
			[movie[i] stop];
			[movie[i] setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieLoopsAttribute];
			
			QTOpenGLTextureContextCreate(kCFAllocatorDefault,								
										 CGLContextObj(CGLGetCurrentContext()),		// the OpenGL context
										 CGLGetPixelFormat(CGLGetCurrentContext()),
										 nil,
										 &textureContext[i]);
			[movie[i] setVisualContext:textureContext[i]];
		}
		
	});		
	
	//
	
}

//
//-----
//

-(void) update:(NSDictionary *)drawingInformation{		
	// check for new frame
	const CVTimeStamp * outputTime;
	[[drawingInformation objectForKey:@"outputTime"] getValue:&outputTime];	
	
	if([movie[PropI(@"video")] currentTime].timeValue >= [movie[PropI(@"video")] duration].timeValue-0.1*[movie[PropI(@"video")] duration].timeScale){
		//Videoen er nået til ende, så gå til næste video
		[Prop(@"video") setIntValue:-1	];
	}		
	
	
	if(PropI(@"video") >= 0 && PropI(@"video") < NUMVIDEOS){
		int i = PropF(@"video");	
		
		if(movie[i] != nil){
			if(lastFramesVideo != i){
				//Video change
				//NSLog(@"Change video %i to %i",lastFramesVideo, i);
				
				dispatch_async(dispatch_get_main_queue(), ^{		
					forceDrawNextFrame = YES;						
					
					[movie[lastFramesVideo] setRate:0.0];	
					[movie[lastFramesVideo] gotoBeginning];				
					[movie[i] gotoBeginning];				
					[movie[i] setRate:1.0];					
				});
				
				lastFramesVideo = i;
			}
			
			if (textureContext[i] != NULL && QTVisualContextIsNewImageAvailable(textureContext[i], outputTime)) {
				// if we have a previous frame release it
				if (NULL != currentFrame[i]) {
					CVOpenGLTextureRelease(currentFrame[i]);
					currentFrame[i] = NULL;
				}
				// get a "frame" (image buffer) from the Visual Context, indexed by the provided time
				OSStatus status = QTVisualContextCopyImageForTime(textureContext[i], NULL, outputTime, &currentFrame[i]);
				
				// the above call may produce a null frame so check for this first
				// if we have a frame, then draw it
				if ( ( status != noErr ) && ( currentFrame[i] != NULL ) )
				{
					NSLog(@"Error: OSStatus: %d",status);
					CFRelease( currentFrame[i] );
					
					currentFrame[i] = NULL;
				} // if
				
			} else if  (textureContext[i] == NULL){
				NSLog(@"No textureContext");
				if (NULL != currentFrame[i]) {
					CVOpenGLTextureRelease(currentFrame[i]);
					currentFrame[i] = NULL;
				}
			}		
		}
	}
}

-(void) draw:(NSDictionary*)drawingInformation{
	if(PropI(@"video") >= 0 && PropI(@"video") < NUMVIDEOS){
		
		//	NSLog(@"Draw");
		int i = PropF(@"video");
		
		if(currentFrame[i] != nil ){		
			//Draw video
			GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
			
			GLenum target = CVOpenGLTextureGetTarget(currentFrame[i]);	
			GLint _name = CVOpenGLTextureGetName(currentFrame[i]);				
			
			// get the texture coordinates for the part of the image that should be displayed
			CVOpenGLTextureGetCleanTexCoords(currentFrame[i], bottomLeft, bottomRight, topRight, topLeft);
			
			
			glEnable(target);
			glBindTexture(target, _name);
			ofSetColor(255,255, 255, 255);						
			glPushMatrix();
			
			[GetPlugin(Keystoner)  applySurface:@"Wall" projectorNumber:0 viewNumber:ViewNumber];
			//		ApplySurface(([NSString stringWithFormat:@"Skærm%i",i+1])){
			glBegin(GL_QUADS);{
				glTexCoord2f(topLeft[0], topLeft[1]);  glVertex2f(0, 0);
				glTexCoord2f(topRight[0], topRight[1]);     glVertex2f(1,  0);
				glTexCoord2f(bottomRight[0], bottomRight[1]);    glVertex2f(1,  1);
				glTexCoord2f(bottomLeft[0], bottomLeft[1]); glVertex2f( 0, 1);
			}glEnd();
			
			
			[GetPlugin(Keystoner)  popSurface];
			
			glPopMatrix();		
			
			glDisable(target);
			
			QTVisualContextTask(textureContext[i]);		
		}
		
		ofEnableAlphaBlending();
	}
}

@end
