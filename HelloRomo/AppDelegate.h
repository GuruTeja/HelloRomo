//
//  AppDelegate.h
//  HelloRomo
//

#import <UIKit/UIKit.h>

@class CMMotionManager;

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

//@property (strong, nonatomic, readonly) CMMotionManager *sharedManager;

- (CMMotionManager *)sharedManager;

@end
