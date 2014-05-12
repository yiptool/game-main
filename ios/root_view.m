
#import "root_view.h"
#import "gl_view_controller.h"

@implementation RootView

-(id)initWithController:(GLViewController *)cntrl
{
	CGRect screenSize = [UIScreen mainScreen].applicationFrame;
	self = [super initWithFrame:screenSize];
	if (!self)
		return nil;

	self.controller = cntrl;
	[self setUserInteractionEnabled:YES];

	return self;
}

-(void)layoutSubviews
{
	[self.controller.glView setFrame:self.bounds];
}

@end
