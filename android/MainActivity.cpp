#include "../opengl_init_options.h"
#include <jni.h>

extern "C"
{
	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeGetInitOptions
		(JNIEnv * env, jobject obj, jobject opts)
	{
		OpenGLInitOptions options;
		GameInstance::instance()->configureOpenGL(options);
		env->SetIntArrayElement(opts, 0, options.redBits);
		env->SetIntArrayElement(opts, 1, options.greenBits);
		env->SetIntArrayElement(opts, 2, options.blueBits);
		env->SetIntArrayElement(opts, 3, options.alphaBits);
		env->SetIntArrayElement(opts, 4, options.depthBits);
		env->SetIntArrayElement(opts, 5, options.stencilBits);
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
