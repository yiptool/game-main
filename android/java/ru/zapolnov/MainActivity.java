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

package ru.zapolnov;

import android.app.Activity;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.support.v4.view.GestureDetectorCompat;
import android.util.Log;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.Window;
import android.view.WindowManager;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class MainActivity extends Activity
	implements GestureDetector.OnGestureListener, GestureDetector.OnDoubleTapListener
{
	private GLSurfaceView m_GLView;
	private GestureDetectorCompat m_GestureDetector;

	@Override protected void onCreate(Bundle bundle)
	{
		super.onCreate(bundle);

		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
			WindowManager.LayoutParams.FLAG_FULLSCREEN);

		int[] opts = new int[6];
		nativeGetInitOptions(opts);
		int redBits = opts[0];
		int greenBits = opts[1];
		int blueBits = opts[2];
		int alphaBits = opts[3];
		int depthBits = opts[4];
		int stencilBits = opts[5];

		m_GLView = new GLSurfaceView(this);
		m_GLView.setEGLContextClientVersion(2);
		m_GLView.setEGLConfigChooser(redBits, greenBits, blueBits, alphaBits, depthBits, stencilBits);

		m_GLView.setRenderer(new GLSurfaceView.Renderer() {
			private long m_PrevTime;
			private int m_Width;
			private int m_Height;
			@Override public void onSurfaceCreated(GL10 gl, EGLConfig config) {
				m_PrevTime = System.currentTimeMillis();
				nativeInit();
			}
			@Override public final void onSurfaceChanged(GL10 gl, int width, int height) {
				m_Width = width;
				m_Height = height;
			}
			@Override public final void onDrawFrame(GL10 gl) {
				long newTime = System.currentTimeMillis();
				long timeDelta = newTime - m_PrevTime;
				m_PrevTime = newTime;
				nativeRunFrame(m_Width, m_Height, timeDelta);
			}
		});

		setContentView(m_GLView);

		m_GestureDetector = new GestureDetectorCompat(this, this);
		m_GestureDetector.setOnDoubleTapListener(this);
	}

	@Override protected final void onPause()
	{
		super.onPause();
		m_GLView.onPause();
	}

	@Override protected final void onResume()
	{
		super.onResume();
		m_GLView.onResume();
	}

	@Override public final boolean onTouchEvent(MotionEvent event)
	{
		m_GestureDetector.onTouchEvent(event);
		return super.onTouchEvent(event);
	}

	@Override public final boolean onDown(MotionEvent event)
	{
		return true;
	}

	@Override public final boolean onFling(MotionEvent event1, MotionEvent event2,
		float velocityX, float velocityY)
	{
		Log.d("Java", "onFling: " + event1.toString() + event2.toString());
		return true;
	}

	@Override public final void onLongPress(MotionEvent event)
	{
		Log.d("Java", "onLongPress: " + event.toString());
	}

	@Override public final boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY)
	{
		Log.d("Java", "onScroll: " + e1.toString() + e2.toString());
		return true;
	}

	@Override public final void onShowPress(MotionEvent event)
	{
		Log.d("Java", "onShowPress: " + event.toString());
	}

	@Override public final boolean onSingleTapUp(MotionEvent event)
	{
		Log.d("Java", "onSingleTapUp: " + event.toString());
		return true;
	}

	@Override public final boolean onDoubleTap(MotionEvent event)
	{
		Log.d("Java", "onDoubleTap: " + event.toString());
		return true;
	}

	@Override public final boolean onDoubleTapEvent(MotionEvent event)
	{
		Log.d("Java", "onDoubleTapEvent: " + event.toString());
		return true;
	}

	@Override public final boolean onSingleTapConfirmed(MotionEvent event)
	{
		Log.d("Java", "onSingleTapConfirmed: " + event.toString());
		return true;
	}

	public static native void nativeGetInitOptions(int[] opts);
	public static native void nativeInit();
	public static native void nativeRunFrame(int width, int height, long time);
}
