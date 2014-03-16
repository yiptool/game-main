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
#import "gl_window.h"
#import "application.h"
#import "util.h"
#import "../game_main.h"
#import <algorithm>

#define FULLSCREEN_STYLE_MASK (NSBorderlessWindowMask)
#define WINDOWED_STYLE_MASK (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask)

/* GLView */

@interface GLView : NSView
{
	NSOpenGLContext * context;
	BOOL initialized;
}
@end

@implementation GLView

-(id)initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
	self = [super initWithFrame:NSZeroRect];
	if (self)
	{
		context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
		if (!context)
		{
			[self dealloc];
			OSX_ThrowError(@"Unable to create OpenGL context.");
		}

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update)
			name:NSViewGlobalFrameDidChangeNotification object:self];
	}
	return self;
}

-(void)dealloc
{
	[self teardownOpenGL];
	[super dealloc];
}

-(void)teardownOpenGL
{
	if (!context)
		return;

	if (initialized)
	{
		[context makeCurrentContext];
		Game::Main::instance()->cleanup();
		initialized = false;
	}

	[NSOpenGLContext clearCurrentContext];
	[context release];
	context = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self
		name:NSViewGlobalFrameDidChangeNotification object:self];
}

-(void)update
{
	[context update];
}

-(void)drawRect:(NSRect)rect
{
	if (!context)
		return;

	if (context.view != self)
		[context setView:self];

	[context makeCurrentContext];

	NSRect bounds = [self convertRectToBacking:[self bounds]];
	int width = (int)bounds.size.width;
	int height = (int)bounds.size.height;
	Game::Main::instance()->setViewportSize_(width, height);

	if (!initialized)
	{
		Game::Main::instance()->init();
		initialized = YES;
	}

	Game::Main::instance()->runFrame();

	[context flushBuffer];
}

@end


/* GLWindow */

@implementation GLWindow

-(id)init
{
	// Query OpenGL settings
	OpenGLInitOptions opt;
	Game::Main::instance()->configureOpenGL(opt);

	// Create the window (call parent constructor)
	NSUInteger styleMask = (opt.fullscreen ? FULLSCREEN_STYLE_MASK : WINDOWED_STYLE_MASK);
	NSRect frame = (opt.fullscreen ?
		[[NSScreen mainScreen] frame] : NSMakeRect(0, 0, opt.desiredWidth, opt.desiredHeight));
	self = [super initWithContentRect:frame styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
	if (!self)
		OSX_ThrowError(@"Unable to create main window.");

	// Configure the window
	self.delegate = self;
	self.restorable = NO;
	self.opaque = YES;
	self.backgroundColor = NSColor.blackColor;
	if (opt.fullscreen)
	{
		self.hidesOnDeactivate = YES;
		self.level = NSMainMenuWindowLevel + 1;
	}

	// Create main view
	[self createOpenGLViewWithOptions:opt];

	// Initiate the rendering
	[self performSelectorOnMainThread:@selector(runFrame) withObject:nil waitUntilDone:NO];

	return self;
}

-(void)dealloc
{
	[self teardownOpenGL];
	[super dealloc];
}

-(void)windowWillClose:(NSNotification *)notification
{
	[[NSApplication sharedApplication] terminate:self];
}

-(void)createOpenGLViewWithOptions:(const OpenGLInitOptions &)opt
{
	// Create pixel format
	int cbits = std::max(0, opt.redBits) + std::max(0, opt.greenBits) + std::max(0, opt.blueBits);
	int abits = std::max(0, opt.alphaBits);
	int dbits = std::max(0, opt.depthBits);
	int sbits = std::max(0, opt.stencilBits);
	NSLog(@"Initializing OpenGL (color: %d, alpha: %d, depth: %d, stencil: %d).\n", cbits, abits, dbits, sbits);
	NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)cbits,
		NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute)abits,
		NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)dbits,
		NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute)sbits,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		(NSOpenGLPixelFormatAttribute)0
	};
	NSOpenGLPixelFormat * pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	if (!pixelFormat)
		OSX_ThrowError(@"Requested pixel format is not supported on this system.");

	// Create the view
	GLView * glview = [[[GLView alloc] initWithPixelFormat:pixelFormat] autorelease];
	if (opt.fullResolution)
		[glview setWantsBestResolutionOpenGLSurface:YES];
	[self setContentView:glview];
	view = glview;
}

-(void)teardownOpenGL
{
	[view teardownOpenGL];
	view = nil;
}

-(void)runFrame
{
	if (!view)
		return;
	[view display];
	[self performSelectorOnMainThread:@selector(runFrame) withObject:nil waitUntilDone:NO];
}

@end
