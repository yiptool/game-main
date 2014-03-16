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
#ifndef __9c737b5fd1ba40f53025d5221a5f0032__
#define __9c737b5fd1ba40f53025d5221a5f0032__

#include <yip-imports/cxx-util/macros.h>
#include <cassert>

namespace Game
{
	/**
	 * Base class for games created using this framework.
	 *
	 * When creating a new game, you have to subclass from this class and override callback methods.
	 * Then use the special macro `GAME_MAIN_CLASS` in the C++ source (**not header**!) file:
	 *
	 * @code
	 * class MyGame : public Game::Main
	 * {
	 *    void init() {}
	 *    void runFrame() {}
	 * };
	 * GAME_MAIN_CLASS(MyGame)
	 * }
	 * @endcode
	 */
	class Main
	{
	public:
		/** Constructor. */
		Main() noexcept;

		/** Destructor. */
		~Main() noexcept;

		/**
		 * Returns pointer to the instance of the game.
		 * @return Pointer to the instance of the game.
		 */
		static Main * instance() noexcept;

		/**
		 * Initializes the game.
		 * This method is called once by the framework to initialize the game.
		 * This method should be overriden in child classes.
		 */
		virtual void init() = 0;

		/**
		 * Runs one game frame.
		 * This method is called by the framework each frame to update the game, render it's contents, etc.
		 * This method should be overriden in child classes.
		 */
		virtual void runFrame() = 0;

	private:
		Main(const Main &) = delete;
		Main & operator=(const Main &) = delete;
	};
}

/**
 * Declares main class for the game.
 * @param CLASS Name of the main class.
 * @see Game::Main.
 */
#define GAME_MAIN_CLASS(CLASS) \
	static CLASS c9737b5fd1ba40f53025d5221a5f0032; \
	extern "C" { \
		DLLEXPORT void * c9737b5fd() { return static_cast<Game::Main *>(&c9737b5fd1ba40f53025d5221a5f0032); } \
	}

#endif