pragma(LDC_no_moduleinfo);

import standard;
import sdl;
import vec;
import draw;
import game;

SDL_Surface* screen;
Game mainGame;

extern(C)
void startup()
{
	SDL_Init(SDL_INIT_VIDEO);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	screen = SDL_SetVideoMode(WIDTH, HEIGHT, 32, SDL_ANYFORMAT | SDL_OPENGL);
	//screen = SDL_SetVideoMode(WIDTH, HEIGHT, 32, SDL_HWSURFACE);
	
	setDrawTarget(screen);

	SDL_WM_SetCaption("The GoD game", null);
	mainGame.init();
}

extern(C)
void mainLoop()
{
	mainGame.processInput();
	mainGame.update();
	mainGame.draw();
	SDL_GL_SwapBuffers();
}
