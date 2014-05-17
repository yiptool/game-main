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
#import "../game_instance.h"
#import "../key_code.h"
#import <algorithm>
#import <yip-imports/cxx-util/macros.h>
#import <mach/mach.h>
#import <mach/mach_time.h>

#define FULLSCREEN_STYLE_MASK (NSBorderlessWindowMask)
#define WINDOWED_STYLE_MASK (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask)

/* GLView */

@interface GLView : NSView
{
	uint64_t prevTime;
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
		GameInstance::instance()->cleanup_();
		initialized = false;
	}

	[NSOpenGLContext clearCurrentContext];
	[context release];
	context = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self
		name:NSViewGlobalFrameDidChangeNotification object:self];
}

-(void)transformEventLocation:(NSEvent *)event andInvoke:(void (^)(int, int))handler
{
	NSPoint pos = [event locationInWindow];
	pos = [self convertPoint:pos fromView:nil];
	pos.y = self.frame.size.height - pos.y;
	handler((int)pos.x, (int)pos.y);
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

	// Update time counters

	uint64_t curTime = mach_absolute_time();
	uint64_t timeDelta;
	if (LIKELY(initialized))
		timeDelta = curTime - prevTime;
	else
		timeDelta = 0;
	prevTime = curTime;

	if (UNLIKELY(timeDelta > 1.0 / 24.0))
		timeDelta = 1.0 / 24.0;

	GameInstance::instance()->setLastFrameTime(timeDelta);
	GameInstance::instance()->setTotalTime(GameInstance::instance()->totalTime() + timeDelta);

	// Adjust for viewport size

	NSRect bounds = [self convertRectToBacking:[self bounds]];
	int width = (int)bounds.size.width;
	int height = (int)bounds.size.height;
	GameInstance::instance()->setViewportSize_(width, height);

	// Run game frame

	if (UNLIKELY(!initialized))
	{
		GameInstance::instance()->init();
		initialized = YES;
	}

	GameInstance::instance()->runFrame_();

	// Present framebuffer to the screen

	[context flushBuffer];
}

@end


/* GLWindow */

@implementation GLWindow

-(id)init
{
	// Query OpenGL settings
	OpenGLInitOptions opt;
	GameInstance::instance()->configureOpenGL(opt);

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
	self.acceptsMouseMovedEvents = YES;
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

// Mouse movement

-(void)mouseDragged:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseMove(x, y);
	}];
}

-(void)rightMouseDragged:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseMove(x, y);
	}];
}

-(void)otherMouseDragged:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseMove(x, y);
	}];
}

-(void)mouseMoved:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseMove(x, y);
	}];
}

// Mouse buttons

-(void)mouseDown:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonDown(x, y, Sys::LeftButton);
	}];
}

-(void)mouseUp:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonUp(x, y, Sys::LeftButton);
	}];
}

-(void)rightMouseDown:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonDown(x, y, Sys::RightButton);
	}];
}

-(void)rightMouseUp:(NSEvent *)event
{
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonUp(x, y, Sys::RightButton);
	}];
}

-(void)otherMouseDown:(NSEvent *)event
{
	if (event.buttonNumber != 2)
		return;
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonDown(x, y, Sys::MiddleButton);
	}];
}

-(void)otherMouseUp:(NSEvent *)event
{
	if (event.buttonNumber != 2)
		return;
	[view transformEventLocation:event andInvoke:^(int x, int y) {
		GameInstance::instance()->onMouseButtonUp(x, y, Sys::MiddleButton);
	}];
}

// Keyboard input

static const unsigned char g_KeyCodeMapping[128] =
{
	Sys::Key_A,
	Sys::Key_S,
	Sys::Key_D,
	Sys::Key_F,
	Sys::Key_H,
	Sys::Key_G,
	Sys::Key_Z,
	Sys::Key_X,
	Sys::Key_C,
	Sys::Key_V,
	Sys::Key_Unknown,
	Sys::Key_B,
	Sys::Key_Q,
	Sys::Key_W,
	Sys::Key_E,
	Sys::Key_R,
	Sys::Key_Y,
	Sys::Key_T,
	Sys::Key_1,
	Sys::Key_2,
	Sys::Key_3,
	Sys::Key_4,
	Sys::Key_6,
	Sys::Key_5,
	Sys::Key_Equal,
	Sys::Key_9,
	Sys::Key_7,
	Sys::Key_Minus,
	Sys::Key_8,
	Sys::Key_0,
	Sys::Key_RightBracket,
	Sys::Key_O,
	Sys::Key_U,
	Sys::Key_LeftBracket,
	Sys::Key_I,
	Sys::Key_P,
	Sys::Key_Enter,
	Sys::Key_L,
	Sys::Key_J,
	Sys::Key_Apostrophe,
	Sys::Key_K,
	Sys::Key_Semicolon,
	Sys::Key_Backslash,
	Sys::Key_Comma,
	Sys::Key_Slash,
	Sys::Key_N,
	Sys::Key_M,
	Sys::Key_Period,
	Sys::Key_Tab,
	Sys::Key_Space,
	Sys::Key_GraveAccent,
	Sys::Key_Backspace,
	Sys::Key_Unknown,
	Sys::Key_Escape,
	Sys::Key_Unknown,			/* Right Command */
	Sys::Key_Unknown,			/* Left Command */
	Sys::Key_LeftShift,
	Sys::Key_CapsLock,
	Sys::Key_LeftAlt,
	Sys::Key_LeftControl,
	Sys::Key_RightShift,
	Sys::Key_RightAlt,
	Sys::Key_RightControl,
	Sys::Key_Unknown,			/* Function */
	Sys::Key_F17,
	Sys::Key_Numeric_Decimal,
	Sys::Key_Unknown,
	Sys::Key_Numeric_Multiply,
	Sys::Key_Unknown,
	Sys::Key_Numeric_Plus,
	Sys::Key_Unknown,
	Sys::Key_NumLock,
	Sys::Key_Unknown,			/* Volume up */
	Sys::Key_Unknown,			/* Volume down */
	Sys::Key_Unknown,			/* Mute */
	Sys::Key_Numeric_Divide,
	Sys::Key_Numeric_Enter,
	Sys::Key_Unknown,
	Sys::Key_Numeric_Minus,
	Sys::Key_F18,
	Sys::Key_F19,
	Sys::Key_Numeric_Equal,
	Sys::Key_Numeric_0,
	Sys::Key_Numeric_1,
	Sys::Key_Numeric_2,
	Sys::Key_Numeric_3,
	Sys::Key_Numeric_4,
	Sys::Key_Numeric_5,
	Sys::Key_Numeric_6,
	Sys::Key_Numeric_7,
	Sys::Key_F20,
	Sys::Key_Numeric_8,
	Sys::Key_Numeric_9,
	Sys::Key_Unknown,
	Sys::Key_Unknown,
	Sys::Key_Unknown,
	Sys::Key_F5,
	Sys::Key_F6,
	Sys::Key_F7,
	Sys::Key_F3,
	Sys::Key_F8,
	Sys::Key_F9,
	Sys::Key_Unknown,
	Sys::Key_F11,
	Sys::Key_Unknown,
	Sys::Key_F13,
	Sys::Key_F16,
	Sys::Key_F14,
	Sys::Key_Unknown,
	Sys::Key_F10,
	Sys::Key_Unknown,
	Sys::Key_F12,
	Sys::Key_Unknown,
	Sys::Key_F15,
	Sys::Key_Unknown,
	Sys::Key_Home,
	Sys::Key_PageUp,
	Sys::Key_Delete,
	Sys::Key_F4,
	Sys::Key_End,
	Sys::Key_F2,
	Sys::Key_PageDown,
	Sys::Key_F1,
	Sys::Key_Left,
	Sys::Key_Right,
	Sys::Key_Down,
	Sys::Key_Up,
	Sys::Key_Unknown,
};

static Sys::KeyCode mapKeyFromOSX(unsigned short key)
{
	if (key < sizeof(g_KeyCodeMapping) / sizeof(g_KeyCodeMapping[0]))
		return static_cast<Sys::KeyCode>(g_KeyCodeMapping[key]);
	return Sys::Key_Unknown;
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)keyDown:(NSEvent *)event
{
	GameInstance::instance()->onKeyPress(mapKeyFromOSX(event.keyCode));

	NSString * text = event.characters;
	NSUInteger length = text.length;
	for (NSUInteger i = 0; i < length; i++)
	{
		uint32_t ch = [text characterAtIndex:i];
		if (ch >= 0xD800 && ch < 0xF900)				// Ignore surrogate pairs and private use area
			continue;
		GameInstance::instance()->onCharInput(ch);
	}
}

-(void)keyUp:(NSEvent *)event
{
	GameInstance::instance()->onKeyRelease(mapKeyFromOSX(event.keyCode));
}

-(void)flagsChanged:(NSEvent *)event
{
	uint32_t flags = event.modifierFlags & NSDeviceIndependentModifierFlagsMask;
	bool isPress = flags > modifierFlags;
	modifierFlags = flags;

	Sys::KeyCode keyCode = mapKeyFromOSX(event.keyCode);
	if (isPress)
		GameInstance::instance()->onKeyPress(keyCode);
	else
		GameInstance::instance()->onKeyRelease(keyCode);
}

@end
