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
#import "util.h"
#import "application.h"
#import <exception>
#import <Cocoa/Cocoa.h>

OpenGLInitOptions g_OpenGLInitOptions;

void OSX_DisplayError(NSString * title, NSString * message)
{
	@autoreleasepool
	{
		NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
		NSImage * alertIcon = [workspace iconForFileType:NSFileTypeForHFSTypeCode(kAlertStopIcon)];

		NSAlert * alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:title];
		[alert setIcon:alertIcon];
		[alert setInformativeText:message];
		[alert runModal];
	}
}

NORETURN void OSX_ThrowError(NSString * message, NSString * title)
{
	@throw [NSException exceptionWithName:title reason:message userInfo:nil];
}

void OSX_CatchExceptions(void (^ code)())
{
	try
	{
		@try
		{
			code();
		}
		@catch (NSException * exception)
		{
			NSLog(@"Unhandled Objective-C exception: %@", exception);
			OSX_DisplayError(exception.name, exception.reason);
			[[Application sharedApplication] terminate:exception];
			@throw;
		}
		@catch (id exception)
		{
			NSLog(@"Unhandled Objective-C exception: %@", exception);
			OSX_DisplayError(@"Unhandled Objective-C exception", [exception description]);
			[[Application sharedApplication] terminate:exception];
			@throw;
		}
	}
	catch (const std::exception & e)
	{
		NSLog(@"Unhandled C++ exception: %s", e.what());
		OSX_DisplayError(@"Unhandled C++ exception", [NSString stringWithUTF8String:e.what()]);
		[[Application sharedApplication] terminate:[Application sharedApplication]];
		throw;
	}
}
