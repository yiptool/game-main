
package ru.zapolnov;

import android.app.Activity;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public final class MainActivity extends Activity
{
	GLSurfaceView m_GLView;

	@Override protected void onCreate(Bundle bundle)
	{
		super.onCreate(bundle);

		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
			WindowManager.LayoutParams.FLAG_FULLSCREEN);

		m_GLView = new GLSurfaceView(this);
		m_GLView.setEGLContextClientVersion(2);
		m_GLView.setEGLConfigChooser(8, 8, 8, 8, 24, 8);
//		m_GLView.setPreserveEGLContextOnPause(true);

		m_GLView.setRenderer(new GLSurfaceView.Renderer() {
			private int m_Width;
			private int m_Height;
			@Override public void onSurfaceCreated(GL10 gl, EGLConfig config) {
				nativeInit();
			}
			@Override public final void onSurfaceChanged(GL10 gl, int width, int height) {
				m_Width = width;
				m_Height = height;
			}
			@Override public final void onDrawFrame(GL10 gl) {
				nativeRunFrame(m_Width, m_Height);
			}
		});

		setContentView(m_GLView);
	}

	@Override protected void onPause()
	{
		super.onPause();
		m_GLView.onPause();
	}

	@Override protected void onResume()
	{
		super.onResume();
		m_GLView.onResume();
	}

	public static native void nativeInit();
	public static native void nativeRunFrame(int width, int height);

	static {
		System.loadLibrary("code");
	}
}
