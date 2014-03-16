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
#import <Cocoa/Cocoa.h>

static void initMainMenu(NSApplication * application)
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

	[application setMainMenu:mainMenu];
}

int main(int argc, char ** argv)
{
	@autoreleasepool
	{
		NSApplication * application = [NSApplication sharedApplication];

		initMainMenu(application);

		[application setActivationPolicy:NSApplicationActivationPolicyRegular];
		[application activateIgnoringOtherApps:YES];
		[application run];
	}

	return 0;
}
