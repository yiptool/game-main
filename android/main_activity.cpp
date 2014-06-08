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
#include "../opengl_init_options.h"
#include "../game_instance.h"
#include <yip-imports/jni_util.h>
#include <yip-imports/jni_int_array.h>
#include <exception>

extern "C"
{
	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeGetInitOptions
		(JNIEnv * env, jobject obj, jintArray opts) noexcept
	{
		jniTryCatch(env, [env, opts]()
		{
			OpenGLInitOptions options;
			GameInstance::instance()->configureOpenGL(options);

			JNI::IntArray arr(env, opts);
			arr[0] = options.redBits;
			arr[1] = options.greenBits;
			arr[2] = options.blueBits;
			arr[3] = options.alphaBits;
			arr[4] = options.depthBits;
			arr[5] = options.stencilBits;
		});
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeInit(JNIEnv * env, jobject obj) noexcept
	{
		jniTryCatch(env, []() {
			GameInstance::instance()->init_();
		});
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeRunFrame(JNIEnv * env, jobject obj,
		jint width, jint height, jlong time) noexcept
	{
		jniTryCatch(env, [width, height, time]()
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
		});
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeTouchBegin(JNIEnv * env, jobject obj,
		jfloat x, jfloat y) noexcept
	{
		jniTryCatch(env, [x, y]()
		{
			GameInstance::instance()->onMouseMove(x, y);
			GameInstance::instance()->onMouseButtonDown(x, y, Sys::LeftButton);
		});
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeTouchContinue(JNIEnv * env, jobject obj,
		jfloat x, jfloat y) noexcept
	{
		jniTryCatch(env, [x, y]()
		{
			GameInstance::instance()->onMouseMove(x, y);
		});
	}

	JNIEXPORT void JNICALL Java_ru_zapolnov_MainActivity_nativeTouchEnd(JNIEnv * env, jobject obj,
		jfloat x, jfloat y) noexcept
	{
		jniTryCatch(env, [x, y]()
		{
			GameInstance::instance()->onMouseButtonUp(x, y, Sys::LeftButton);
		});
	}
}
