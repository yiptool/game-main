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

-(id)initWithController:(GLViewController *)cntrl
{
	self = [super initWithTargetScreen:[UIScreen mainScreen]];
	if (self)
		controller = cntrl;
	return self;
}

-(const OpenGLInitOptions &)initOptions
{
	if (UNLIKELY(!hasInitOptions))
		GameInstance::instance()->configureOpenGL(initOptions);
	return initOptions;
}

-(BOOL)fullResolution
{
	return self.initOptions.fullResolution;
}

-(NSString *)eaglColorFormat
{
	const OpenGLInitOptions & opt = self.initOptions;
	if (opt.redBits <= 5 && opt.greenBits <= 6 && opt.blueBits <= 5 && opt.alphaBits <= 0)
		return kEAGLColorFormatRGB565;
	return kEAGLColorFormatRGBA8;
}

-(int)depthBits
{
	return self.initOptions.depthBits;
}

-(int)stencilBits
{
	return self.initOptions.stencilBits;
}

-(void)initGL
{
	GameInstance::instance()->init_();
}

-(void)cleanupGL
{
	GameInstance::instance()->cleanup_();
}

-(void)resizeGL:(CGSize)size
{
	GameInstance::instance()->setViewportSize_(int(size.width), int(size.height));
}

-(void)renderWidth:(CGFloat)width height:(CGFloat)height time:(CFTimeInterval)timeDelta
{
	GameInstance::instance()->setLastFrameTime(timeDelta);
	GameInstance::instance()->setTotalTime(GameInstance::instance()->totalTime() + timeDelta);
	GameInstance::instance()->runFrame_();
}

-(void)didRenderFirstFrame
{
	// Dismiss splash if it is still displayed
	[controller dismissSplash];
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
