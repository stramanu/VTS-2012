//
//  MacNetworkingTestingAppDelegate.h
//  MacNetworkingTesting
//
//  Created by Brad Larson on 3/16/2010.
//

#import <Cocoa/Cocoa.h>
#import "Server.h"

@interface MacNetworkingTestingAppDelegate : NSObject <NSApplicationDelegate, ServerDelegate> 
{
	IBOutlet NSTableView *tableView;
    NSWindow *window;
	Server *_server;
	NSMutableArray *_services;
	NSString *textToSend, *_message;
	NSInteger selectedRow, connectedRow;
	BOOL isConnectedToService;
    int calibrationMode;
    NSPoint a; //1
    NSPoint b; //2
    NSPoint c; //3
    NSPoint d; //4
    
    NSPoint wFocus;
    NSPoint hFocus;
    NSPoint wRif;
    NSPoint hRif;
    NSPoint pWRif;
    NSPoint pHRif;
    
    NSMutableArray *smoothPointer;
    NSPoint smoothPoint;
    
    int time;
    NSTimer *timer;
    BOOL arrayUpdate;
    
    IBOutlet NSTextField *vertexCal;

}

- (void)mouseDownTime;
- (BOOL)isNearA:(NSPoint)a B:(NSPoint)b;

- (NSPoint)sistA:(NSPoint)A B:(NSPoint)B C:(NSPoint)C D:(NSPoint)D;
- (NSPoint)sistA:(NSPoint)A B:(NSPoint)B P:(NSPoint)P pCoeff:(CGFloat)pCoeff;
- (CGFloat)distA:(NSPoint)A B:(NSPoint)B;

- (IBAction)calibrationModeChangeBtn:(id)sender;
- (void)moveCursorXY:(NSPoint)point;


@property (assign) IBOutlet NSWindow *window;
@property(nonatomic, retain) Server *server;
@property(nonatomic, retain) NSMutableArray *services;
@property(readwrite, copy) NSString *message;
@property(readwrite, nonatomic) BOOL isConnectedToService;

// Interface methods
- (IBAction)connectToService:(id)sender;
- (IBAction)sendText:(id)sender;

@end
