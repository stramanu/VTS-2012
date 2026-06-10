//
//  MacNetworkingTestingAppDelegate.m
//  MacNetworkingTesting
//
//  Created by Brad Larson on 3/16/2010.
//

#import "MacNetworkingTestingAppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>
@implementation MacNetworkingTestingAppDelegate

@synthesize window;

- (IBAction)calibrationModeChangeBtn:(id)sender {
    
    calibrationMode = 1;
    
    a.x = 0;
    b.x = 0;
    c.x = 0;
    d.x = 0;
    
    [vertexCal setStringValue:@"calib"];
    
    NSLog(@"%d",calibrationMode);
    
}

- (CGFloat)distA:(NSPoint)A B:(NSPoint)B{
    
    return sqrtf(powf((A.x-B.x),2) + powf((A.y-B.y),2));
}

- (NSPoint)sistA:(NSPoint)A B:(NSPoint)B C:(NSPoint)C D:(NSPoint)D{
    
    CGFloat mAB = (B.y-A.y)/(B.x-A.x);
    CGFloat mCD = (D.y-C.y)/(D.x-C.x);
    
    CGFloat xRes = (-A.y+(mAB*A.x)+C.y-(mCD*C.x))/(mAB-mCD);
    CGFloat yRes = A.y+(mAB*(xRes-A.x));
    
    return NSMakePoint(xRes, yRes);
    
}

- (NSPoint)sistA:(NSPoint)A B:(NSPoint)B P:(NSPoint)P pCoeff:(CGFloat)pCoeff{
    
    CGFloat mAB = (B.y-A.y)/(B.x-A.x);
    
    CGFloat xRes = (-A.y+(mAB*A.x)+P.y-(pCoeff*P.x))/(mAB-pCoeff);
    CGFloat yRes = A.y+(mAB*(xRes-A.x));
    
    return NSMakePoint(xRes, yRes);
    
}

- (void)mouseDownTime{
        
    if (time>0) {
        
        time--;
                
    }else{
        
        if(timer)
        {
            [timer invalidate];
            timer = nil;
            
            NSLog(@"MouseUp");
            //MouseUp
            CGEventPost(kCGSessionEventTap,CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp,smoothPoint, kCGMouseButtonLeft));
            [smoothPointer removeAllObjects];

        }
    }
    
}

- (void)moveCursorXY:(NSPoint)point{
    
    
    
    hFocus = [self sistA:a B:b C:c D:d];
    wFocus = [self sistA:d B:a C:b D:c];
    
    CGFloat wFhFCoeff = (hFocus.y-wFocus.y)/(hFocus.x-wFocus.x);
    
    wRif = [self sistA:wFocus B:a P:b pCoeff:wFhFCoeff];
    hRif = [self sistA:d B:hFocus P:b pCoeff:wFhFCoeff];
    
    CGFloat width = [self distA:wRif B:b];
    CGFloat height =[self distA:b B:hRif];
    
    pWRif = [self sistA:wFocus B:point P:b pCoeff:wFhFCoeff];
    pHRif = [self sistA:point B:hFocus P:b pCoeff:wFhFCoeff];
    
    CGFloat deltaX = [self distA:wRif B:pWRif];
    CGFloat deltaY = [self distA:hRif B:pHRif];
    
    NSArray *screenArray = [NSScreen screens];
    CGFloat widthScreen = [[screenArray objectAtIndex:0] frame].size.width;
    CGFloat heightScreen = [[screenArray objectAtIndex:0] frame].size.height;

    NSPoint newCoord = NSMakePoint((deltaX*widthScreen)/width,heightScreen-((deltaY*heightScreen)/height));
    
    CGFloat dist = [self distA:[[smoothPointer lastObject]pointValue] B:newCoord];
    
    if (([smoothPointer count]>1)&&(dist>50)) {
        [smoothPointer removeAllObjects];
    }
    
    [smoothPointer addObject:[NSValue valueWithPoint:newCoord]];
    
    if ([smoothPointer count]>8) {
        [smoothPointer removeObjectAtIndex:0];
    }
    
    smoothPoint.x = 0;
    smoothPoint.y = 0;
    
    for (int i=0; i<[smoothPointer count]; i++) {
        
        smoothPoint.x += [[smoothPointer objectAtIndex:i]pointValue].x;
        smoothPoint.y += [[smoothPointer objectAtIndex:i]pointValue].y;
        
    }
    
    smoothPoint.x /= [smoothPointer count];
    smoothPoint.y /= [smoothPointer count];
    
    time = 5;
    
    if (![timer isValid]) {
        
        NSLog(@"MouseDown");
        //MouseDown
        CGEventPost(kCGSessionEventTap,CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, smoothPoint,kCGMouseButtonLeft));

        
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(mouseDownTime) userInfo:nil repeats:YES];
        
    }
    
    CGEventPost(kCGSessionEventTap,CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, smoothPoint,kCGMouseButtonLeft));
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    arrayUpdate = NO;
    
    smoothPointer = [[NSMutableArray alloc]init];
    
    calibrationMode = -1;
        
	self.message = @"Message";
	connectedRow = -1;
	self.services = [[NSMutableArray alloc] init];
	
	NSString *type = @"TestingProtocol";

	_server = [[Server alloc] initWithProtocol:type];
    _server.delegate = self;

    NSError *error = nil;
    if(![_server start:&error]) {
        NSLog(@"error = %@", error);
    }
    
}

- (void)dealloc
{
	[_server release];
	[_services release];
	[_message release];
	[super dealloc];
}

#pragma mark -
#pragma mark Interface methods

- (IBAction)connectToService:(id)sender;
{
	[self.server connectToRemoteService:[self.services objectAtIndex:selectedRow]];
}

- (IBAction)sendText:(id)sender;
{
	NSData *data = [textToSend dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	[self.server sendData:data error:&error];
	
}

#pragma mark -
#pragma mark Server delegate methods

- (void)serverRemoteConnectionComplete:(Server *)server 
{
    NSLog(@"Connected to service");
	
	self.isConnectedToService = YES;

	connectedRow = selectedRow;
	[tableView reloadData];
}

- (void)serverStopped:(Server *)server 
{
    NSLog(@"Disconnected from service");

	self.isConnectedToService = NO;

	connectedRow = -1;
	[tableView reloadData];
}

- (void)server:(Server *)server didNotStart:(NSDictionary *)errorDict 
{
    NSLog(@"Server did not start %@", errorDict);
}

- (BOOL)isNearA:(NSPoint)aPoint B:(NSPoint)bPoint{
    
    CGFloat dist = sqrtf(powf(aPoint.x-bPoint.x, 2)+powf(aPoint.y-bPoint.y, 2));
    
    return (dist<30);
    
}

- (void)server:(Server *)server didAcceptData:(NSData *)data 
{
    
    NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    float x = [[str substringToIndex:[str rangeOfString:@"-"].location]floatValue];
    float y = [[str substringFromIndex:[str rangeOfString:@"-"].location+1]floatValue];
 
    NSPoint point = NSMakePoint(x, y);
    
    
    switch (calibrationMode) {
        case 5:
            
            [self moveCursorXY:point];
            
            break;
            
        case 1:
            
            if (a.x==0) {
                a = point;
                [vertexCal setStringValue:@"A"];
            }else{
                if (![self isNearA:point B:a]) {
                    calibrationMode = 2;
                }else{
                    a = point;
                    [vertexCal setStringValue:@"A"];
                }
            }
            
            break;
            
        case 2:
            if (b.x==0) {
                b = point;
                [vertexCal setStringValue:@"B"];
            }else{
                if (![self isNearA:point B:b]) {
                    calibrationMode = 3;
                }else{
                    b = point;
                    [vertexCal setStringValue:@"B"];
                }
            }
            break;
            
        case 3:
            if (c.x==0) {
                c = point;
                [vertexCal setStringValue:@"C"];
            }else{
                if (![self isNearA:point B:c]) {
                    calibrationMode = 4;
                }else{
                    c = point;
                    [vertexCal setStringValue:@"C"];
                }
            }
            break;
            
        case 4:
            if (d.x==0) {
                d = point;
                [vertexCal setStringValue:@"D"];
            }else{
                if (![self isNearA:point B:d]) {
                    calibrationMode = 5;
                }else{
                    d = point;
                    [vertexCal setStringValue:@"D"];
                }
            }
            break;
            
        default:
            break;
    }
    
}

- (void)server:(Server *)server lostConnection:(NSDictionary *)errorDict 
{
	NSLog(@"Lost connection");
	
	self.isConnectedToService = NO;
	connectedRow = -1;
	[tableView reloadData];
}

- (void)serviceAdded:(NSNetService *)service moreComing:(BOOL)more 
{
	NSLog(@"Added a service: %@", [service name]);
	
    [self.services addObject:service];
    if(!more) {
        [tableView reloadData];
    }
}

- (void)serviceRemoved:(NSNetService *)service moreComing:(BOOL)more 
{
	NSLog(@"Removed a service: %@", [service name]);
	
    [self.services removeObject:service];
    if(!more) {
        [tableView reloadData];
    }
}

#pragma mark -
#pragma mark NSTableView delegate methods

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (rowIndex == connectedRow)
		[aCell setTextColor:[NSColor redColor]];
	else
		[aCell setTextColor:[NSColor blackColor]];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return [[self.services objectAtIndex:rowIndex] name];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSLog(@"Count: %d", [self.services count]);
    return [self.services count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	selectedRow = [[aNotification object] selectedRow];
}

#pragma mark -
#pragma mark Accessors

@synthesize server = _server;
@synthesize services = _services;
@synthesize message = _message;
@synthesize isConnectedToService;


@end
