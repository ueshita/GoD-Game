pragma(LDC_no_moduleinfo);

import sdl;
import vec;

private SDL_Surface* drawTarget = null;

struct Color
{
	int r, g, b, a;
}

void setDrawTarget(SDL_Surface* target)
{
	drawTarget = target;
}

void drawLine(Vec2 pos1, Vec2 pos2, Color color)
{
	lineRGBA(drawTarget, pos1.x, pos1.y, pos2.x, pos2.y, color.r, color.g, color.b, color.a);
}

void drawRectLeftTop(Vec2 pos, Vec2 size, Color color)
{
	boxRGBA(drawTarget, pos.x, pos.y, pos.x + size.x, pos.y + size.y, color.r, color.g, color.b, color.a);
}

void drawRect(Vec2 pos, Vec2 size, Color color)
{
	boxRGBA(drawTarget, 
		pos.x - size.x / 2, pos.y - size.y / 2, 
		pos.x + size.x / 2, pos.y + size.y / 2, 
		color.r, color.g, color.b, color.a);
}

struct Sprite
{
	SDL_Surface* surface;
	SDL_Rect rect;

	this(SDL_Surface* surface, int x = 0, int y = 0, int w = 0, int h = 0) {
		this.surface = surface;
		this.rect.x = x;
		this.rect.y = y;
		this.rect.w = (w > 0) ? w : surface.w;
		this.rect.h = (h > 0) ? h : surface.h; 
	}

	void draw(Vec2 pos, Vec2 size)
	{
		SDL_Rect srcrect, dstrect;
		dstrect.x = pos.x - size.x / 2;
		dstrect.y = pos.y - size.y / 2;
		dstrect.w = size.x;
		dstrect.h = size.y;
		SDL_BlitScaled(this.surface, &this.rect, drawTarget, &dstrect);
	}
}
