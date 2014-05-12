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
#import <UIKit/UIKit.h>

@class GLViewController;

@interface GLView : UIView <UIGestureRecognizerDelegate>
{
	float scaleFactor;
	GLuint framebuffer;
	GLuint renderbuffer;
	CGSize renderbufferSize;
	BOOL firstFrame;
}
@property (nonatomic, assign) GLViewController * controller;
@property (nonatomic, assign) CAEAGLLayer * eaglLayer;
@property (nonatomic, retain) EAGLContext * eaglContext;
-(id)initWithController:(GLViewController *)cntrl;
@end
