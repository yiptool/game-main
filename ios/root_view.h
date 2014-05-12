
#import <UIKit/UIKit.h>

@class GLViewController;

@interface RootView : UIView
@property (nonatomic, assign) GLViewController * controller;
-(id)initWithController:(GLViewController *)cntrl;
@end
