//
//  ViewController.m
//  HelloRomo
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "AppDelegate.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

static const NSTimeInterval accelerometerMin = 0.1;

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define PORT 1234

@interface ViewController () {
    dispatch_queue_t socketQueue;
    NSMutableArray *connectedSockets;
    BOOL isRunning;
    
    GCDAsyncSocket *listenSocket;
}

@end

@implementation ViewController

#pragma mark - View Management
double a;
double b;
double c;
double speed=0.6;
double heading;
double radius = 0;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // To receive messages when Robots connect & disconnect, set RMCore's delegate to self
    [RMCore setDelegate:self];
    
    // Grab a shared instance of the Romo character
    self.Romo = [RMCharacter Romo];
    [RMCore setDelegate:self];
    
    [self addGestureRecognizers];
    
    // Do any additional setup after loading the view, typically from a nib.
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
    
    NSLog(@"%@", [self getIPAddress]);
    
    [self toggleSocketState];   //Statrting the Socket
    
    [self startUpdatesWithSliderValue:100];
    [self perform:@"GO"];
    NSLog(@"out of method");
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // Add Romo's face to self.view whenever the view will appear
    [self.Romo addToSuperview:self.view];
}

#pragma mark -
#pragma mark Accelerometer

- (void)startUpdatesWithSliderValue:(int)sliderValue
{
    NSLog(@"in startUpdateswithSliderValue Accelerometer");
    NSTimeInterval delta = 0.05;
    NSTimeInterval updateInterval = accelerometerMin + delta * sliderValue;
    
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
   // ViewController * __weak weakSelf = self;
    if ([mManager isAccelerometerAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            a = accelerometerData.acceleration.x;
            b = accelerometerData.acceleration.y;
            c = accelerometerData.acceleration.z;
            NSLog(@"x value is");
            NSLog(@"%f",a);
            NSLog(@"y value is");
            NSLog(@"%f",b);
            NSLog(@"z value is");
            NSLog(@"%f",c);
            if (a >= -0.01 & b <= -0.90 & c<=-0.01) {
                speed = speed + 0.5; //speed = 0.7
                
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            //declination
            else if ((a >= 0.03 & a <= 0.06) & (b >= -1.0 & b <= -0.96 )& (c >=0.07 & c<= 0.24)){
                
                speed = speed - 0.1;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            
            else if ((a >= 0.03 & a <= 0.06) & (b >= -0.96 & b <= -0.85 )& (c >=0.24 & c<= 0.38)){
               
                speed = speed - 0.2;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.03 & a < 0.06) & (b >= -0.96 & b <= -0.85 )& (c >=0.38 & c<= 0.50)){
                
                speed = speed - 0.3;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.01 & a <= 0.10) & (b >= -0.84 & b <= -0.65 )& (c >=0.50 & c<= 0.70)){
                
                speed = speed - 0.4;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            // inclination from high

            
            else if ((a <= 0.170 & a >= 0.040) & (b >= -0.65 & b <= -0.85 )& (c >= -0.80 & c<= -0.50)){
                
                speed = speed + 0.5;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a <= 0.040 & a>= 0.15) & (b >= -0.75 & b <= -0.95 )& (c >=-0.50 & c<= -0.40)){
                
                speed = speed + 0.4;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a <= 0.010 & a> 0.040) & (b >= -0.65 & b <= -0.75 )& (c >=0.70 & c<= 0.60)){
                
                speed = speed + 0.3;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else{
                
                speed = speed;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
        
        }];
    }
    
    //self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
}


#pragma mark -
#pragma mark Robo Movement

- (NSString *)direction:(NSString *)message {
    
    return @"";
}

- (void)perform:(NSString *)command {
    
    
    NSString *cmd = [command uppercaseString];
    
    NSLog(@"In Command");
    NSLog(@"%@",cmd); // cmd has the string comming from client .
    
    
    if ([cmd isEqualToString:@"GO"]) {
        NSLog(@"%f",speed);
        

        if (a >= 0.12 & b <=0.70 & c<=0.75) {
            speed = speed + 0.5;
            NSLog(@"ur in x,y,z, loop");
            [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                if (success) {
                    [self.Romo3 driveForwardWithSpeed:speed];
                }
            }];
        }else{
            NSLog(@"ur here");
        }
        
        //speed=speed+0.3;

    }
    else if ([cmd isEqualToString:@"10 METRES"]) {
        speed=speed-0.2;
        [self.Romo3 driveWithRadius:1.1 speed:speed];
        //[self.Romo3 turnByAngle:0 withRadius:1.1 completion:^(BOOL success, float heading) ];
        
    }
    else if ([cmd isEqualToString:@"20 METRES"]) {
        speed=speed-0.3;
        [self.Romo3 turnByAngle:0 withRadius:.30 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveWithRadius:RM_DRIVE_RADIUS_STRAIGHT speed:0.3];
            }
        }];
        
    }
    else if ([cmd isEqualToString:@"30 METRES"]) {
        speed=speed-0.3;
        [self.Romo3 turnByAngle:0 withRadius:.30 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveWithRadius:0.3 speed:0.3];
            }
        }];
        
    }
    else if ([cmd isEqualToString:@"BACKWARD"]) {
        speed=speed-0.3;
        [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveForwardWithSpeed:speed];
            }
        }];
        
    }
    else if ([cmd isEqualToString:@"DOWN"]) {
        speed=speed-0.3;
        [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveForwardWithSpeed:speed];
            }
        }];
        
    }
    else if ([cmd isEqualToString:@"LEFT"]) {
        [self.Romo3 turnByAngle:-90 withRadius:0.0 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveForwardWithSpeed:speed];
            }
        }];
    } else if ([cmd isEqualToString:@"RIGHT"]) {
        [self.Romo3 turnByAngle:90 withRadius:0.0 completion:^(BOOL success, float heading) {
            [self.Romo3 driveForwardWithSpeed:speed];
        }];
    } else if ([cmd isEqualToString:@"BACK"]) {
        [self.Romo3 driveBackwardWithSpeed:speed];
    } else if ([cmd isEqualToString:@"GO"]) {
        if(speed <= 0){
            speed = 0.3;
            [self.Romo3 driveForwardWithSpeed:speed];
            NSLog(@"%f",speed);
        }
        else{
            
            [self.Romo3 driveForwardWithSpeed:speed];NSLog(@"%f",speed);
        }
    } else if ([cmd isEqualToString:@"SMILE"]) {
        self.Romo.expression=RMCharacterExpressionChuckle;
        self.Romo.emotion=RMCharacterEmotionHappy;
    } else if([cmd isEqualToString:@"STOP"]){
        [self.Romo3 stopDriving];
    }
    else if ([cmd isEqualToString:@"FAST"]) {
        speed=speed+1.0;
        [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
            if (success) {
                [self.Romo3 driveForwardWithSpeed:speed];
            }
        }];
        NSLog(@"%f",speed);
    }
    else if ([cmd isEqualToString:@"SLOW"]) {
        if((speed-1.0) > 0){
            
            [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                if (success) {
                    [self.Romo3 driveForwardWithSpeed:speed];
                }
            }];
        }
    }
    
    else if ([cmd isEqualToString:@"SLEEPY"]) {
        self.Romo.expression=RMCharacterExpressionSleepy;
        self.Romo.emotion=RMCharacterEmotionSleepy;
    }
    else if ([cmd isEqualToString:@"BEWILDERED"]) {
        self.Romo.expression=RMCharacterExpressionBewildered;
        self.Romo.emotion=RMCharacterEmotionBewildered;
    }
    else if ([cmd isEqualToString:@"CRY"]) {
        self.Romo.expression=RMCharacterExpressionSad;
        self.Romo.emotion=RMCharacterEmotionSad;
    }
    else if ([cmd isEqualToString:@"SCARED"]) {
        self.Romo.expression=RMCharacterExpressionScared;
        self.Romo.emotion=RMCharacterEmotionScared;
    }
    else if ([cmd isEqualToString:@"CHUCKLE"]) {
        self.Romo.expression=RMCharacterExpressionChuckle;
        self.Romo.emotion=RMCharacterEmotionCurious;
    }
    else if ([cmd isEqualToString:@"BORED"]) {
        self.Romo.expression=RMCharacterExpressionBored;
        self.Romo.emotion=RMCharacterEmotionCurious;
    }
}

#pragma mark - RMCoreDelegate Methods
- (void)robotDidConnect:(RMCoreRobot *)robot
{
    // Currently the only kind of robot is Romo3, so this is just future-proofing
    if ([robot isKindOfClass:[RMCoreRobotRomo3 class]]) {
        self.Romo3 = (RMCoreRobotRomo3 *)robot;
        
        // Change Romo's LED to be solid at 80% power
        [self.Romo3.LEDs setSolidWithBrightness:0.8];
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionExcited;
    }
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot
{
    if (robot == self.Romo3) {
        self.Romo3 = nil;
        
        // When we unpluged Romo , he get's sad!
        self.Romo.expression = RMCharacterExpressionSad;
    }
}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    // Let's start by adding some gesture recognizers with which to interact with Romo
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UITapGestureRecognizer *tapReceived = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedScreen:)];
    [self.view addGestureRecognizer:tapReceived];
}

- (void)driveLeft {
    
}

- (void)swipedLeft:(UIGestureRecognizer *)sender
{
    [self.Romo3 turnByAngle:-90 withRadius:0.0 completion:NULL];
    // When the user swipes left, Romo will turn in a circle to his left
    //[self.Romo3 driveWithRadius:-1.0 speed:1.0];
}

- (void)swipedRight:(UIGestureRecognizer *)sender
{
    [self.Romo3 turnByAngle:90 withRadius:0.0 completion:NULL];
    // When the user swipes right, Romo will turn in a circle to his right
    //    [self.Romo3 driveWithRadius:1.0 speed:1.0];
}

// Swipe up to change Romo's emotion to some random emotion
- (void)swipedUp:(UIGestureRecognizer *)sender
{
    int numberOfEmotions = 7;
    
    // Choose a random emotion from 1 to numberOfEmotions
    // That's different from the current emotion
    RMCharacterEmotion randomEmotion = 1 + (arc4random() % numberOfEmotions);
    
    self.Romo.emotion = randomEmotion;
}

// Simply tap the screen to stop Romo
- (void)tappedScreen:(UIGestureRecognizer *)sender
{
    [self.Romo3 stopDriving];
}

#pragma mark -
#pragma mark Socket

- (void)toggleSocketState
{
    if(!isRunning)
    {
        NSError *error = nil;
        if(![listenSocket acceptOnPort:PORT error:&error])
        {
            [self log:FORMAT(@"Error starting server: %@", error)];
            return;
        }
        
        [self log:FORMAT(@"Echo server started on port %hu", [listenSocket localPort])];
        isRunning = YES;
    }
    else
    {
        // Stop accepting connections
        [listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        
        [self log:@"Stopped Echo server"];
        isRunning = false;
    }
}

- (void)log:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

#pragma mark -
#pragma mark GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            [self log:FORMAT(@"Accepted client %@:%hu", host, port)];
            
        }
    });
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    
    [newSocket readDataWithTimeout:READ_TIMEOUT tag:0];
    newSocket.delegate = self;
    
    //    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:100 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"In socket didReadData");
    NSLog(@"== didReadData %@ ==", sock.description);
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self log:msg];
    [self perform:msg];
    [sock readDataWithTimeout:READ_TIMEOUT tag:0];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self log:FORMAT(@"Client Disconnected")];
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}

@end
