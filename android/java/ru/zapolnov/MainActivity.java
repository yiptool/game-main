
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

	public static native void nativeGetInitOptions(int[] opts);
	public static native void nativeInit();
	public static native void nativeRunFrame(int width, int height, long time);

	static {
		System.loadLibrary("code");
	}
}
