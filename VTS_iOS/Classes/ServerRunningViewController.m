//
//  ServerRunningViewController.m
//  NetworkingTesting
//
//  Created by Bill Dudney on 2/20/09.
//  Copyright 2009 Gala Factory Software LLC. All rights reserved.
//

#import "ServerRunningViewController.h"
#import "Server.h"

@implementation ServerRunningViewController

@synthesize message = _message;
@synthesize server = _server;
@synthesize captureSession = _captureSession;
@synthesize imageView = _imageView;
@synthesize customLayer = _customLayer;
@synthesize prevLayer = _prevLayer;

#pragma mark -
#pragma mark Initialization
- (id)init {
	self = [super init];
	if (self) {
		/*We initialize some variables (they might be not initialized depending on what is commented or not)*/
		self.imageView = nil;
		self.prevLayer = nil;
		self.customLayer = nil;
	}
	return self;
}

- (void)viewDidLoad {
                
    /*We intialize the capture*/
	[self initCapture];

}

- (void)initCapture {
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
										  error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	//captureOutput.minFrameDuration = CMTimeMake(1, 10);
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
	[captureOutput setVideoSettings:videoSettings];
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
	/*We add the preview layer*/
	self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	self.prevLayer.frame = self.view.frame;
	self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.prevLayer];
    
	/*We start the capture*/
	[self.captureSession startRunning];
	
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	//We create an autorelease pool because as we are not in the main_queue our code is
	 //not executed in the main thread. So we have to create an autorelease pool for the thread we are in
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    //Get information about the image
    
    unsigned char* baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
    //size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    //size_t width = CVPixelBufferGetWidth(imageBuffer);
    //size_t height = CVPixelBufferGetHeight(imageBuffer);
    
	//Codice elaborazione pixel
    
    //NSMutableArray *pixelSelectArray = [NSMutableArray arrayWithCapacity:480*360];
    NSMutableArray *areasPx = [[NSMutableArray alloc]init];
    //[areasPx addObject:[[NSMutableArray alloc]init]] ;
    CGFloat dist = 10;
    
    
    
    for (int i=0; i<480*360*4; i+=4*9) {
        
        float red = (float)baseAddress[i+2];
        float green = (float)baseAddress[i+1];
        float blue = (float)baseAddress[i];
        
        double luminance = (red/255.0f)*0.299 + (green/255.0f)*0.587 + (blue/255.0f)*0.114;
        
        if (luminance>0.8) {
            
            int index = i/4;
            float y = roundf(index / 480);
            float x = index % 480;
                            
            //[pixelSelectArray addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
            int area = 0;
            int px = 0;
            BOOL trovato = NO;
            
            //[[areasPx objectAtIndex:0]addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
            
            while ((!trovato)&&(area<[areasPx count])) {
                while ((!trovato)&&(px<[[areasPx objectAtIndex:area]count])) {
                    
                    float x2 = [[[areasPx objectAtIndex:area]objectAtIndex:px]CGPointValue].x;
                    float y2 = [[[areasPx objectAtIndex:area]objectAtIndex:px]CGPointValue].y;
                    
                    CGFloat dist2 = sqrtf(powf(x2-x, 2)+powf(y2-y, 2));
                    
                    if (dist2<=dist) {
                        
                        trovato=YES;
                   
                    }
                    px++;
                }
                px = 0;
                area++;
            }
            
            if (trovato) {
                
                [[areasPx objectAtIndex:area-1]addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
            
            }else{
                
                [areasPx addObject:[[NSMutableArray alloc]init]] ;
                [[areasPx objectAtIndex:[areasPx count]-1]addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
                    
            }
                
        }
        
    }
    
    if ([areasPx count]>0) {
        
    
    if ([[areasPx objectAtIndex:0]count] >0) {
        
        float x=0;
        float y=0;
        
        for (int i=0; i<[[areasPx objectAtIndex:0]count]; i++) {
            
            x += [[[areasPx objectAtIndex:0]objectAtIndex:i]CGPointValue].x;
            y += [[[areasPx objectAtIndex:0]objectAtIndex:i]CGPointValue].y;
            
        }
        
        x /= [[areasPx objectAtIndex:0]count];
        y /= [[areasPx objectAtIndex:0]count];
        
        //NSString *str = [NSString stringWithFormat:@"%d-%d",[[areasPx objectAtIndex:0]count],[areasPx count]];
        NSString *str = [NSString stringWithFormat:@"%f-%f",x,y];
        //NSMutableData *data = [NSMutableData dataWithCapacit:0];
        //[data appendBytes:&px length:sizeof(int[2])];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        
        [self.server sendData:data error:&error];
        [self.server sendData:data error:&error];
        [self.server sendData:data error:&error];
                
    }
    }
             
    //We unlock the  image buffer

	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    [pool drain];
	
	
}


- (void)setMessage:(NSString *)message {
    
    NSLog(message);
    
}


#pragma mark Memory management

- (void)viewDidUnload {
    self.imageView = nil;
    self.customLayer = nil;
    self.prevLayer = nil;
    
}

- (void)dealloc {
    [self.captureSession release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

@end
