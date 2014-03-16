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
#import "application.h"
#import "util.h"
#import "gl_window.h"

@implementation Application

@synthesize glWindow;

-(id)init
{
	self = [super init];
	if (self)
	{
		self.delegate = self;
		[self initMainMenu];
	}
	return self;
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification
{
	@autoreleasepool
	{
		[self setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
	@autoreleasepool
	{
		OSX_CatchExceptions(^{
			self.glWindow = [[[GLWindow alloc] init] autorelease];
			[glWindow makeKeyAndOrderFront:self];
		});
		[self setActivationPolicy:NSApplicationActivationPolicyRegular];
		[self activateIgnoringOtherApps:YES];
		NSLog(@"Application has started.");
	}
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
	@autoreleasepool
	{
		NSLog(@"Application is terminating.");
		OSX_CatchExceptions(^{
			[glWindow teardownOpenGL];
			[glWindow resignKeyWindow];
			self.glWindow = nil;
		});
	}
}

-(void)initMainMenu
{
	@autoreleasepool
	{
		NSString * programName = [[[NSProcessInfo processInfo] processName] capitalizedString];
		NSString * quitTitle = [@"Quit " stringByAppendingString:programName];

		NSMenuItem * quitMenuItem = [[NSMenuItem alloc] autorelease];
		[quitMenuItem initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];

		NSMenu * appMenu = [[NSMenu new] autorelease];
		[appMenu addItem:quitMenuItem];

		NSMenuItem * appMenuItem = [[NSMenuItem new] autorelease];
		[appMenuItem setSubmenu:appMenu];

		NSMenu * mainMenu = [[NSMenu new] autorelease];
		[mainMenu addItem:appMenuItem];

		[self setMainMenu:mainMenu];
	}
}

@end
