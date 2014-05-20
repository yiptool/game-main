#include "../opengl_init_options.h"
#include "../game_instance.h"
#include <jni.h>

extern "C"
{
	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeGetInitOptions
		(JNIEnv * env, jobject obj, jintArray opts)
	{
		OpenGLInitOptions options;
		GameInstance::instance()->configureOpenGL(options);

		jint * arr = env->GetIntArrayElements(opts, 0);
		arr[0] = options.redBits;
		arr[1] = options.greenBits;
		arr[2] = options.blueBits;
		arr[3] = options.alphaBits;
		arr[4] = options.depthBits;
		arr[5] = options.stencilBits;
		env->ReleaseIntArrayElements(opts, arr, 0);
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeInit(JNIEnv * env, jobject obj)
	{
		GameInstance::instance()->init_();
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeRunFrame(JNIEnv * env, jobject obj,
		jint width, jint height, jlong time)
	{
		double timeDelta = double(time);
		if (UNLIKELY(timeDelta < 0.0))
			timeDelta = 0.0;
		else if (UNLIKELY(timeDelta > 1.0 / 24.0))
			timeDelta = 1.0 / 24.0;

		GameInstance::instance()->setLastFrameTime(timeDelta);
		GameInstance::instance()->setTotalTime(GameInstance::instance()->totalTime() + timeDelta);

		GameInstance::instance()->setViewportSize_(width, height);
		GameInstance::instance()->runFrame_();
	}
}
