/* vim: set ai noet ts=4 sw=4 tw=115: */
//
// Copyright (c) 2014 Nikolay Zapolnov (zapolnov@gmail.com).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "gl_view_controller.h"
#import "splash_view_controller.h"
#import "gl_view.h"
#import "root_view.h"

@implementation GLViewController

@synthesize glView;

-(void)loadView
{
	self.view = [[[RootView alloc] initWithController:self] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	self.glView = [[[GLView alloc] initWithController:self] autorelease];
	[self.view addSubview:glView];
}

-(void)presentSplash
{
	SplashViewController * splashController = [[[SplashViewController alloc] init] autorelease];
	splashController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:splashController animated:NO completion:nil];
}

-(void)dismissSplash
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)shouldAutorotate
{
	return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
	NSUInteger mask = 0;
	NSArray * array = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
	for (NSString * string in array)
	{
		if ([string isEqualToString:@"UIInterfaceOrientationPortrait"])
			mask |= UIInterfaceOrientationMaskPortrait;
		if ([string isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"])
			mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
		if ([string isEqualToString:@"UIInterfaceOrientationLandscapeLeft"])
			mask |= UIInterfaceOrientationMaskLandscapeLeft;
		if ([string isEqualToString:@"UIInterfaceOrientationLandscapeRight"])
			mask |= UIInterfaceOrientationMaskLandscapeRight;
	}
	return mask;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

@end
