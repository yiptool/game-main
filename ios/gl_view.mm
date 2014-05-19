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
#import <QuartzCore/QuartzCore.h>
#import <yip-imports/cxx-util/macros.h>
#import "../game_instance.h"
#import "gl_view.h"
#import "gl_view_controller.h"

@implementation GLView

@synthesize controller;
@synthesize eaglLayer;
@synthesize eaglContext;

+(Class)layerClass
{
	return [CAEAGLLayer class];
}

-(id)initWithController:(GLViewController *)cntrl
{
	CGRect screenSize = [UIScreen mainScreen].applicationFrame;
	self = [super initWithFrame:screenSize];
	if (!self)
		return nil;

	self.controller = cntrl;
	framebuffer = 0;
	renderbuffer = 0;
	firstFrame = YES;

	scaleFactor = 1.0f;
	if ([self respondsToSelector:@selector(contentScaleFactor)])
	{
		scaleFactor = [[UIScreen mainScreen] scale];
		self.contentScaleFactor = scaleFactor;
	}

	// Query OpenGL settings
	GameInstance::instance()->configureOpenGL(initOptions);

	self.eaglLayer = (CAEAGLLayer *)self.layer;
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
		kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
		nil
	];

	self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	if (!eaglContext)
	{
		[self release];
		return nil;
	}

	if (![EAGLContext setCurrentContext:eaglContext])
	{
		[self release];
		return nil;
	}

	CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

	UITapGestureRecognizer * tapGestureRecognizer = [[[UITapGestureRecognizer alloc]
		initWithTarget:self action:@selector(handleTap:)] autorelease];
	[tapGestureRecognizer setNumberOfTapsRequired:1];
	[tapGestureRecognizer setNumberOfTouchesRequired:1];
	[self addGestureRecognizer:tapGestureRecognizer];

	UIPanGestureRecognizer * panGestureRecognizer = [[[UIPanGestureRecognizer alloc]
		initWithTarget:self action:@selector(handlePan:)] autorelease];
	[self addGestureRecognizer:panGestureRecognizer];

	UIPinchGestureRecognizer * pinchGestureRecognizer = [[[UIPinchGestureRecognizer alloc]
		initWithTarget:self action:@selector(handlePinch:)] autorelease];
	[self addGestureRecognizer:pinchGestureRecognizer];

	UILongPressGestureRecognizer * longPressGestureRecognizer = [[[UILongPressGestureRecognizer alloc]
		initWithTarget:self action:@selector(handleLongPress:)] autorelease];
	[self addGestureRecognizer:longPressGestureRecognizer];

	[self setUserInteractionEnabled:YES];

	return self;
}

-(void)dealloc
{
	if (!firstFrame)
	{
		if ([EAGLContext setCurrentContext:eaglContext])
			GameInstance::instance()->cleanup_();
		[EAGLContext setCurrentContext:nil];
	}
	self.eaglContext = nil;
	[super dealloc];
}

-(void)createFramebuffer:(CGSize)size
{
	NSLog(@"Creating framebuffer with size %dx%d.", int(size.width), int(size.height));

	glGenFramebuffers(1, &framebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

	glGenRenderbuffers(1, &renderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
	[eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);

	if (initOptions.depthBits > 0 || initOptions.stencilBits > 0)
	{
		glGenRenderbuffers(1, &depthStencilRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, depthStencilRenderbuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, int(size.width), int(size.height));
		if (initOptions.depthBits > 0)
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthStencilRenderbuffer);
		if (initOptions.stencilBits > 0)
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthStencilRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
	}

	renderbufferSize = size;
}

-(void)destroyFramebuffer
{
	if (framebuffer)
	{
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glDeleteFramebuffers(1, &framebuffer);
		framebuffer = 0;
	}

	if (renderbuffer)
	{
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		glDeleteRenderbuffers(1, &renderbuffer);
		renderbuffer = 0;
	}

	if (depthStencilRenderbuffer)
	{
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		glDeleteRenderbuffers(1, &depthStencilRenderbuffer);
		depthStencilRenderbuffer = 0;
	}
}

-(void)render:(CADisplayLink *)displayLink
{
	@autoreleasepool
	{
		[EAGLContext setCurrentContext:eaglContext];

		// Update time counters

		CFTimeInterval curTime = displayLink.timestamp;
		CFTimeInterval timeDelta;
		if (LIKELY(!firstFrame))
			timeDelta = curTime - prevTime;
		else
			timeDelta = 0;
		prevTime = curTime;

		if (UNLIKELY(timeDelta > 1.0 / 24.0))
			timeDelta = 1.0 / 24.0;

		GameInstance::instance()->setLastFrameTime(timeDelta);
		GameInstance::instance()->setTotalTime(GameInstance::instance()->totalTime() + timeDelta);

		// Adjust for viewport size

		CGSize size = self.bounds.size;
		size.width *= scaleFactor;
		size.height *= scaleFactor;

		if (UNLIKELY(!framebuffer || !renderbuffer ||
			size.width != renderbufferSize.width || size.height != renderbufferSize.height))
		{
			[self destroyFramebuffer];
			[self createFramebuffer:size];
		}

		GameInstance::instance()->setViewportSize_(int(size.width), int(size.height));

		// Run game frame

		if (UNLIKELY(firstFrame))
			GameInstance::instance()->init_();

		GameInstance::instance()->runFrame_();

		// Present framebuffer to the screen

		glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
		[eaglContext presentRenderbuffer:GL_RENDERBUFFER];

		// Dismiss splash if it is still displayed

		if (UNLIKELY(firstFrame))
		{
			[controller dismissSplash];
			firstFrame = NO;
		}
	}
}

-(void)handleTap:(UIGestureRecognizer *)recognizer
{
/*
	CGPoint location = [recognizer locationInView:recognizer.view];

	int x = (int)(location.x * scaleFactor);
	int y = (int)(location.y * scaleFactor);

	GameInstance::instance()->onTap(x, y);
*/
}

-(void)handlePan:(UIGestureRecognizer *)recognizer
{
	CGPoint location = [recognizer locationInView:recognizer.view];
	CGPoint translation = [(UIPanGestureRecognizer *)recognizer translationInView:recognizer.view];
	CGPoint velocity = [(UIPanGestureRecognizer *)recognizer velocityInView:recognizer.view];

	int x = (int)(location.x * scaleFactor);
	int y = (int)(location.y * scaleFactor);
	int dx = (int)(translation.x * scaleFactor);
	int dy = (int)(translation.y * scaleFactor);
	float vx = (float)(velocity.x * scaleFactor);
	float vy = (float)(velocity.y * scaleFactor);

	switch (recognizer.state)
	{
	case UIGestureRecognizerStatePossible: return;
	case UIGestureRecognizerStateFailed: return;
	case UIGestureRecognizerStateBegan: GameInstance::instance()->onMouseButtonDown(x, y, Sys::LeftButton); break;
	case UIGestureRecognizerStateChanged: GameInstance::instance()->onMouseMove(x, y); break;
	case UIGestureRecognizerStateEnded: GameInstance::instance()->onMouseButtonUp(x, y, Sys::LeftButton); break;
	case UIGestureRecognizerStateCancelled: GameInstance::instance()->onMouseButtonUp(x, y, Sys::LeftButton); break;
	}
}

-(void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
/*
	CGPoint location = [recognizer locationInView:recognizer.view];
	float scale = recognizer.scale;

	int x = (int)(location.x * scaleFactor);
	int y = (int)(location.y * scaleFactor);

	GameInstance::instance()->onPinch(x, y);
*/
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
/*
	if (recognizer.state == UIGestureRecognizerStateBegan)
	{
		CGPoint location = [recognizer locationInView:recognizer.view];

		int x = (int)(location.x * scaleFactor);
		int y = (int)(location.y * scaleFactor);

		GameInstance::instance(0->onLongPress(x, y);
	}
*/
}

@end
