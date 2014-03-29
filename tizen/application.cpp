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
#include "application.h"
#include <new>
#include <FBase.h>
#include <FUi.h>
#include <FApp.h>
#include <FGraphicsOpengl2.h>

//using namespace Tizen::Base;
//using namespace Tizen::Base::Collection;
//using namespace Tizen::Base::Runtime;
//using namespace Tizen::Graphics;
//using namespace Tizen::Locales;
//using namespace Tizen::System;
//using namespace Tizen::App;
//using namespace Tizen::System;
//using namespace Tizen::Ui;
//using namespace Tizen::Ui::Controls;
//using namespace Tizen::Graphics::Opengl;

/* OpenGLForm */

namespace
{
	class OpenGLForm : public Tizen::Ui::Controls::Form
	{
	public:
		result OnDraw() override;
	};
}

result OpenGLForm::OnDraw()
{
	return E_SUCCESS;
}


/* TizenApplication */

namespace
{
	class TizenApplication : public Tizen::App::Application
	{
	public:
		bool OnAppInitializing(Tizen::App::AppRegistry & appRegistry) override;
		bool OnAppTerminating(Tizen::App::AppRegistry & appRegistry, bool urgentTermination = false) override;
	};
}

bool TizenApplication::OnAppInitializing(Tizen::App::AppRegistry & appRegistry)
{
	return true;
}

bool TizenApplication::OnAppTerminating(Tizen::App::AppRegistry & appRegistry, bool urgentTermination)
{
	return true;
}


/* Entry point */

static Tizen::App::Application * CreateApp()
{
	return new (std::nothrow) TizenApplication;
}

extern "C"
{
	_EXPORT_ int OspMain(int argc, char ** pArgv)
	{
		Tizen::Base::Collection::ArrayList args;

		args.Construct();
		for (int i = 0; i < argc; i++)
			args.Add(*(new (std::nothrow) Tizen::Base::String(pArgv[i])));

		result r = Tizen::App::Application::Execute(CreateApp, &args);
		TryLog(r == E_SUCCESS, "[%s] Application execution failed", GetErrorMessage(r));

		args.RemoveAll(true);

		return static_cast<int>(r);
	}
}
