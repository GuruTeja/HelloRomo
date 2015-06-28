//
//  ViewController.m
//  HelloRomo
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "AppDelegate.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"
#import <math.h>

using namespace std;
using namespace cv;

static const NSTimeInterval accelerometerMin = 0.1;
static BOOL _debug = NO;

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
    
    CMMotionManager *mManager;
}

@end

@implementation ViewController

#pragma mark - View Management
double a;
double b;
double c;
double speed;
double speed1=0.6;
double heading;
double j = 0;
double confidence;
double maxradius = 1;
double excess1 = 0;
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
    
    //-[self startUpdatesWithSliderValue:100];
    //-[self perform:@"GO"];
    NSLog(@"out of method");
    [self tappedOnRed];
    [self startUpdatesWithSliderValue:100];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // Add Romo's face to self.view whenever the view will appear
    [self.Romo addToSuperview:self.view];
}

- (void)tappedOnRed {
    _min = 160;
    _max = 179;
    
    NSLog(@"%.2f - %.2f", _min, _max);
}

#pragma mark - OpenCV

- (void)didCaptureIplImage:(IplImage *)iplImage
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    /* Converts input array pixels from one color space to another */
    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
    Mat matRGB = Mat(imgRGB);
    
    //ipl image is also converted to HSV; hue is used to find certain color
    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);
    
    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);
    
    //it is important to release all images EXCEPT the one that is going to be passed to
    //the didFinishProcessingImage: method and displayed in the UIImageView
    cvReleaseImage(&iplImage);
    
    //filter all pixels in defined range, everything in range will be white, everything else
    //is going to be black
    cvInRangeS(imgHSV, cvScalar(_min, 100, 100), cvScalar(_max, 255, 255), imgThreshed);
    
    cvReleaseImage(&imgHSV);
    
    Mat matThreshed = Mat(imgThreshed);
    
    //smooths edges
    cv::GaussianBlur(matThreshed,
                     matThreshed,
                     cv::Size(9, 9),
                     2,
                     2);
    
    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
    if (_debug)
    {
        cvReleaseImage(&imgRGB);
        [self didFinishProcessingImage:imgThreshed];
    }
    else
    {
        vector<Vec3f> circles;
        
        //get circles
        HoughCircles(matThreshed,
                     circles,
                     CV_HOUGH_GRADIENT,
                     2,
                     matThreshed.rows / 4,
                     150,
                     75,
                     10,
                     150);
        
        for (size_t i = 0; i < circles.size(); i++)
        {
            cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            int radius1 = radius;
            maxradius = MAX(maxradius, radius1);
            j = j + (i+1);
            circle(matRGB, center, 3, Scalar(0, 255, 0), -1, 8, 0);
            circle(matRGB, center, radius, Scalar(0, 0, 255), 3, 8, 0);
        }
        
        confidence = j/100;
        NSLog(@"confidence value is:%f",confidence);
        if (confidence > 0.10 & maxradius > 20) {
            NSLog(@"confidence level reached to stop the romo");
            self.Romo.expression=RMCharacterExpressionAngry;
            self.Romo.emotion=RMCharacterEmotionBewildered;
            [self.Romo3 stopDriving];
            _debug = YES;
            [mManager stopAccelerometerUpdates];
           
        }
        //threshed image is not needed any more and needs to be released
        cvReleaseImage(&imgThreshed);
        
        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
        //method will take care of that
        [self didFinishProcessingImage:imgRGB];
    }
}

#pragma mark -
#pragma mark Accelerometer

- (void)startUpdatesWithSliderValue:(int)sliderValue
{
    
    NSLog(@"in startUpdateswithSliderValue Accelerometer");
    NSTimeInterval delta = 0.02;
    NSTimeInterval updateInterval = accelerometerMin + delta * sliderValue;
    
    mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    NSLog(@"check accelerometer");
    
   // ViewController * __weak weakSelf = self;
    if ([mManager isAccelerometerAvailable] == YES) {
        NSLog(@"accelerometer is present");
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
            NSLog(@"ur here");
            if ((a <= 0.35 & a>= -0.35) & (b <= -0.80 & b >= -0.93) & (c<=0.56 & c>= -0.67)) {
                speed = speed1; //speed = 0.2
                NSLog(@"in loop1");
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            //inclination
            else if ((a <= 0.35 & a >= -0.35) & (b >= -0.78 & b <= -0.50 )& (c >= -0.90 & c<= -0.58)){
                 NSLog(@"in loop2");
                speed = speed1 + 0.2;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionExcited;
                        self.Romo.emotion=RMCharacterEmotionExcited;
                        [self.Romo3 driveForwardWithSpeed:speed];
                        
                    }
                }];
            }
            else if ((a <= 0.35 & a >= -0.35) & (b <= -0.30 & b >= -0.45 )& (c >= -1.0 & c<= -0.85)){
                
                if(excess1 >0){
                     NSLog(@"in other loop excess >1");
                    [self.Romo3 driveBackwardWithSpeed:0.5];
                    excess1 = 0;
                }
                else{
                    NSLog(@"in loop3");
                    speed = speed1 + 0.4;
                    NSLog(@"speed is : %f",speed);
                    [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionExcited;
                        self.Romo.emotion=RMCharacterEmotionExcited;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                    }];
                }
            }
            else if ((a <= 0.35 & a >= -0.35) & ((b >=-0.25  & b <= -0.001) || (b >= -0.55 & b <= -0.75 ) )& (c >= -1.10 & c <= -0.76)){
                if(excess1 >0){
                     NSLog(@"in other loop excess >1");
                    [self.Romo3 driveBackwardWithSpeed:0.7];
                    excess1 = 0;
                }
                else{
                 NSLog(@"in loop4");
                speed = speed1 + 0.6;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionExhausted;
                        self.Romo.emotion=RMCharacterEmotionSleepy;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
                }
             }
            

            
            // declination
            
            else if ((a <= 0.35 & a >= -0.35) & (b >= -1.0 & b <= -0.80 )& (c >= -0.55 & c<= -0.35)){
                 NSLog(@"in loop5");
                speed = speed1 - 0.2;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                            self.Romo.expression=RMCharacterExpressionScared;
                            self.Romo.emotion=RMCharacterEmotionScared;
                            [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }

            else if ((a <= 0.35 & a >= -0.35)& ((b <= 1.0 & b >= -0.99) || (b >= -1.0 & b <= -0.80) )& (c >= -0.40 & c<= -0.15)){
                if(excess1 >0){
                     NSLog(@"in other loop excess >1");
                    [self.Romo3 driveForwardWithSpeed:0.7];
                    excess1 = 0;
                }
                else{
                 NSLog(@"in loop6");
                speed = speed1 - 0.3;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionBored;
                        self.Romo.emotion=RMCharacterEmotionBewildered;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
                }
            }
            
            else if ((a <= 0.35 & a >= -0.35)& ((b <= 1.0 & b >= -0.99) || (b >= -1.0 & b <= -0.80) )& (c >= -0.15 & c<= 0.15)){
                if(excess1 >0){
                    NSLog(@"in other loop excess >1");
                    [self.Romo3 driveForwardWithSpeed:0.5];
                    excess1 =0;
                }
                else{
                    NSLog(@"in loop7");
                    speed = speed1 - 0.3;
                    NSLog(@"speed is : %f",speed);
                    [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionBored;
                        self.Romo.emotion=RMCharacterEmotionBewildered;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                    }];
                }
            }
            //stop in excess decination
            else if ((a <= 0.35 & a >= -0.35)& ((b <= 1.0 & b >= -0.99) || (b >= -1.0 & b <= -0.80) )& (c >= 0.10 & c<= 1.10)){
                //excess1 =  excess1 +1;
                //NSLog(@"excess value is :%f",excess1);
                self.Romo.expression=RMCharacterExpressionDizzy;
                self.Romo.emotion=RMCharacterEmotionIndifferent;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 stopDriving];
                    }
                }];
            }
                //stop in excess inclination
            else if (((a <= 0.35 & a >= -0.35) & (b >= -0.01 & b <= 0.22 )& (c >= -1.10 & c <= -0.76))){
               // excess1 = excess1 +1;
                //NSLog(@"excess value is :%f",excess1);
                self.Romo.expression=RMCharacterExpressionDizzy;
                self.Romo.emotion=RMCharacterEmotionIndifferent;
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 stopDriving];
                    }
                }];            }
        }];
    }
    //self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
}


#pragma mark -
#pragma mark Robo Movement

- (NSString *)direction:(NSString *)message {
    
    return @"";
}

/*- (void)perform:(NSString *)command {
    
    
    NSString *cmd = [command uppercaseString];
    
    //NSLog(@"In Command");
    //NSLog(@"%@",cmd); // cmd has the string comming from client .
    //start
    
    NSLog(@"in startUpdateswithSliderValue Accelerometer");
    NSTimeInterval delta = 0.01;
    NSTimeInterval updateInterval = accelerometerMin + delta * 100;
    
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    
    // ViewController * __weak weakSelf = self;
    if ([mManager isAccelerometerAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            a = accelerometerData.acceleration.x;
            b = accelerometerData.acceleration.y;
            c = accelerometerData.acceleration.z;

            if ([cmd isEqualToString:@"GO"]){
                NSLog(@"x value is");
                NSLog(@"%f",a);
                NSLog(@"y value is");
                NSLog(@"%f",b);
                NSLog(@"z value is");
                NSLog(@"%f",c);
            if ((a <= 0.35 & a>= -0.35) & (b <= -0.96 & b >= -0.99) & (c<=0.18 & c>= -0.20)) {
                speed = speed1 + 0.2; //speed = 0.8
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            //declination
            else if ((a <= 0.35 & a >= -0.35) & (b >= -0.92 & b <= -0.96 )& (c <=0.34 & c>= 0.16)){
                
                speed = speed1 - 0.2;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionChuckle;
                        self.Romo.emotion=RMCharacterEmotionHappy;
                        [self.Romo3 driveForwardWithSpeed:speed];
                        
                    }
                }];
            }
            
            else if ((a >= 0.35 & a <= -0.35) & (b >= -0.90 & b <= -0.85 )& (c >=0.48 & c<= 0.32)){
                
                speed = speed1 - 0.4;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionChuckle;
                        self.Romo.emotion=RMCharacterEmotionHappy;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.35 & a <= -0.35) & (b >= -0.95 & b <= -0.60 )& (c >=0.44 & c<= 0.70)){
                
                speed = speed1 - 0.6;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionChuckle;
                        self.Romo.emotion=RMCharacterEmotionHappy;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            // inclination from high
            
            
            else if ((a >= 0.35 & a <= -0.35) & (b >= -0.98 & b <= -0.94 )& (c >= -0.35 & c<= -0.16)){
                
                speed = speed1 + 0.1;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionScared;
                        self.Romo.emotion=RMCharacterEmotionScared;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.35 & a <= -0.35) & (b >= -0.92 & b <= -0.85 )& (c >=-0.50 & c<= -0.32)){
                
                speed = speed1 + 0.2;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionScared;
                        self.Romo.emotion=RMCharacterEmotionScared;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.35 & a <= -0.35)& (b >= -0.90 & b <= -0.70 )& (c >= -0.75 & c<= -0.48)){
                
                speed = speed1 + 0.3;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionScared;
                        self.Romo.emotion=RMCharacterEmotionScared;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
            else if ((a >= 0.35 & a <= -0.35)& (b >= -0.68 & b <= -0.60 )& (c >= -0.80 & c<= -0.72)){
                
                speed = speed1 + 0.4;
                NSLog(@"speed is : %f",speed);
                [self.Romo3 turnByAngle:0 withRadius:0.0 completion:^(BOOL success, float heading) {
                    if (success) {
                        self.Romo.expression=RMCharacterExpressionScared;
                        self.Romo.emotion=RMCharacterEmotionScared;
                        [self.Romo3 driveForwardWithSpeed:speed];
                    }
                }];
            }
                //stop
            else if ((a >= 0.35 & a <= -0.35)& (b >= -0.33 & b <= 0.03 )& (c >= -1.00 & c<= -0.80)){
                
                   [self.Romo3 stopDriving];
                    self.Romo.expression=RMCharacterExpressionSad;
                    self.Romo.emotion=RMCharacterEmotionSad;
            }
            else if ((a >= 0.35 & a <= -0.35)& (b >= -0.05 & b <= 0.1 )& (c >= -.024 & c<= 0.02)){
                
                    [self.Romo3 stopDriving];
                    self.Romo.expression=RMCharacterExpressionSad;
                    self.Romo.emotion=RMCharacterEmotionSad;
            }
                
                
            }}
         ];
    }
    
    if ([cmd isEqualToString:@"10 METRES"]) {
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
                [self.Romo3 driveBackwardWithSpeed:speed];
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
} */

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
/*- (void)swipedUp:(UIGestureRecognizer *)sender
{
    int numberOfEmotions = 7;
    
    // Choose a random emotion from 1 to numberOfEmotions
    // That's different from the current emotion
    RMCharacterEmotion randomEmotion = 1 + (arc4random() % numberOfEmotions);
    
    self.Romo.emotion = randomEmotion;
}*/

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
    //[self perform:msg];
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
