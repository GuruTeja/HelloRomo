//
//  ViewController.h
//  HelloRomo
//

#import <UIKit/UIKit.h>
#import <RMCore/RMCore.h>
#import <RMCharacter/RMCharacter.h>
#import "AbstractOCVViewController.h"


@interface ViewController : AbstractOCVViewController <RMCoreDelegate> {
    double _min, _max;
}

@property (nonatomic, strong) RMCoreRobotRomo3 *Romo3;
@property (nonatomic, strong) RMCharacter *Romo;

- (void)addGestureRecognizers;

@end
