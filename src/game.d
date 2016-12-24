pragma(LDC_no_moduleinfo);

import standard;
import sdl;
import vec;
import draw;

extern(C) int rand();
extern(C) void quit();

enum WIDTH = 480;
enum HEIGHT = 480;

struct Game
{
	const int boardAreaSize = HEIGHT;
	const Color boardAreaColor = Color(150, 240, 140, 255);
	const Color lineColor = Color(255, 255, 255, 255);

	const int boardPadding = 8;
	const int boardSize = boardAreaSize - boardPadding * 2;
	const int cellSize = boardSize / 8;
	const Vec2 pieceSize = Vec2(64, 64);
	const int animTime = 30;
	const int enemyWaitTime = 10;
	
	enum State {
		PlayerTurn,
		PlayerAnim,
		EnemyTurn,
		EnemyAnim,
		Finished
	}

	struct MouseInput {
		uint buttons;

		int x, y;
		bool pressed;
	}

	struct Cell {
		Vec2 pos;
		int owner;
	}

	State state;
	MouseInput mouse;
	Cell[8][8] cells;
	Sprite[3] pieces;
	Vec2 cursor;

	Vec2[64] turnBuffer;
	Vec2[] turnIndexes;
	int frameCount;

	void init() {
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				auto cell = &cells[x][y];
				cell.pos.x = boardPadding + x * cellSize + cellSize / 2;
				cell.pos.y = boardPadding + y * cellSize + cellSize / 2;
			}
		}
		pieces[1] = Sprite(IMG_Load("res/chara1.png"));
		pieces[2] = Sprite(IMG_Load("res/chara2.png"));
		
		reset();

		printf("The GoD game\n");
		printf("Created by ueshita (@ueshita)\n");
		printf("Thanks for dscripten (https://github.com/Ace17/dscripten)\n");
		printf("------------------------------------------------\n");
		printf("Game started.\n");
	}

	void reset() {
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				auto cell = &cells[x][y];
				cell.owner = 0;
			}
		}
		cells[3][3].owner = 1;
		cells[3][4].owner = 2;
		cells[4][3].owner = 2;
		cells[4][4].owner = 1;
	}

	void processInput() {
		SDL_PumpEvents();

		uint last = mouse.buttons;
		uint current = SDL_GetMouseState(&mouse.x, &mouse.y);
		mouse.pressed = ((current & ~last & SDL_BUTTON_LMASK) != 0);
		mouse.buttons = current;

		// update cursor
		if (mouse.x >= boardPadding && 
			mouse.y >= boardPadding && 
			mouse.x < boardPadding + boardSize && 
			mouse.y < boardPadding + boardSize
		) {
			cursor.x = (mouse.x - boardPadding) / cellSize;
			cursor.y = (mouse.y - boardPadding) / cellSize;
		} else {
			cursor.x = -1;
			cursor.y = -1;
		}

		if (state == State.PlayerTurn) {
			if (isCursorInBoard() && mouse.pressed) {
				if (addPiece(cursor, 1)) {
					setState(State.PlayerAnim);
				}
			}
		}
	}

	void update() {
		if (state == State.PlayerAnim) {
			if (++frameCount >= animTime) {
				setState(State.EnemyTurn);
			}
		}
		if (state == State.EnemyAnim) {
			if (++frameCount >= animTime) {
				setState(State.PlayerTurn);
			}
		}

		if (state == State.PlayerTurn ||
			state == State.EnemyTurn
		) {
			if (getCountOfOwnersCell(0) == 0) {
				setState(State.Finished);

				int count1 = getCountOfOwnersCell(1);
				int count2 = getCountOfOwnersCell(2);
				printf("D-man:%d    Gopher:%d\n", count1, count2);
				if (count1 > count2) {
					printf("D-man won!!\n");
				} else if (count1 < count2) {
					printf("Gopher won!!\n");
				} else {
					printf("Drawn game...\n");
				}
				return;
			}
		}

		if (state == State.PlayerTurn) {
			Vec2[64] buffer;
			Vec2[] indexes = findCellsIsAbleToAddPiece(1, buffer);
			if (indexes.length == 0) {
				setState(State.EnemyTurn);
			}
		}

		if (state == State.EnemyTurn) {
			if (++frameCount >= enemyWaitTime) {
				Vec2[64] buffer;
				Vec2[] indexes = findCellsIsAbleToAddPiece(2, buffer);
				if (indexes.length) {
					int chosen = rand() % indexes.length;
					addPiece(indexes[chosen], 2);
					setState(State.EnemyAnim);
				} else {
					setState(State.PlayerTurn);
				}
			}
		}
	}

	void draw() {
		// Clear screen
		drawRectLeftTop(Vec2(0, 0), Vec2(boardAreaSize, boardAreaSize), boardAreaColor);
		
		// Draw board lines
		for (int x = 0; x <= 8; x++) {
			drawLine(Vec2(boardPadding + x * cellSize, boardPadding), 
				Vec2(boardPadding + x * cellSize, boardPadding + boardSize), 
				lineColor);
		}
		for (int y = 0; y <= 8; y++) {
			drawLine(Vec2(boardPadding, boardPadding + y * cellSize), 
				Vec2(boardPadding + boardSize, boardPadding + y * cellSize), 
				lineColor);
		}

		// Draw all pieces
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				auto cell = &cells[x][y];
				if (cell.owner > 0) {
					if (isPieceTurning(Vec2(x, y))) {
						if (state == State.PlayerAnim) {
							pieces[2].draw(cell.pos, pieceSize * (animTime - frameCount) / animTime);
							pieces[1].draw(cell.pos, pieceSize * frameCount / animTime);
						} else if (state == State.EnemyAnim) {
							pieces[1].draw(cell.pos, pieceSize * (animTime - frameCount) / animTime);
							pieces[2].draw(cell.pos, pieceSize * frameCount / animTime);
						}
					} else {
						pieces[cell.owner].draw(cell.pos, pieceSize);
					}
				}
			}
		}

		// Draw cursor
		if (isCursorInBoard()) {
			Vec2[64] buffer;
			Vec2[] indexes = findCellsIsAbleToAddPiece(1, buffer);
			for (int i = 0; i < indexes.length; i++) {
				if (cursor.x == indexes[i].x && cursor.y == indexes[i].y) {
					drawRect(Vec2(
						boardPadding + cursor.x * cellSize + cellSize / 2, 
						boardPadding + cursor.y * cellSize + cellSize / 2), 
						Vec2(cellSize, cellSize), Color(200, 200, 200, 128));
					break;
				}
			}
		}
	}

private:
	void setState(State state) {
		this.state = state;
		this.frameCount = 0;
		if (state == State.PlayerTurn ||
			state == State.EnemyTurn
		) {
			turnIndexes = null;
		}
	}

	bool addPiece(Vec2 pos, int owner) {
		turnIndexes = findCellsIsAbleToTurn(pos, owner, turnBuffer);
		Vec2[] indexes =  turnIndexes;
		if (indexes.length > 0) {
			cells[pos.x][pos.y].owner = owner;
			for (int i = 0; i < indexes.length; i++) {
				auto cell = &cells[indexes[i].x][indexes[i].y];
				cell.owner = owner;
			}
			return true;
		} else {
			return false;
		}
	}

	bool isCursorInBoard() const {
		return (cursor.x >= 0 && cursor.y >= 0);
	}

	bool isPieceTurning(Vec2 pos) const {
		if (turnIndexes == null) {
			return false;
		}
		for (int i = 0; i < turnIndexes.length; i++) {
			if (turnIndexes[i].x == pos.x && turnIndexes[i].y == pos.y) {
				return true;
			}
		}
		return false;
	}

	Vec2[] findCellsIsAbleToTurnDir(Vec2 pos, Vec2 dir, int owner, Vec2[] buffer) const {
		int count = 0;
		while (true) {
			pos += dir;
			if (pos.x >= 0 && pos.y >= 0 && pos.x < 8 && pos.y < 8) {
				auto cell = &cells[pos.x][pos.y];
				if (count > 0 && cell.owner == owner) {
					return buffer[0..count];
				} else if (cell.owner != 0 && cell.owner != owner) {
					buffer[count++] = Vec2(pos.x, pos.y);
				} else {
					break;
				}
			} else {
				break;
			}
		}
		return buffer[0..0];
	}

	Vec2[] findCellsIsAbleToTurn(Vec2 pos, int owner, Vec2[] buffer) const {
		auto cell = &cells[pos.x][pos.y];
		int count = 0;
		if (cell.owner == 0) {
			count += findCellsIsAbleToTurnDir(pos, Vec2(-1, -1), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2( 0, -1), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2(+1, -1), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2(-1,  0), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2(+1,  0), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2(-1, +1), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2( 0, +1), owner, buffer[count..$]).length;
			count += findCellsIsAbleToTurnDir(pos, Vec2(+1, +1), owner, buffer[count..$]).length;
		}
		return buffer[0..count];
	}

	Vec2[] findCellsIsAbleToAddPiece(int owner, Vec2[] buffer) const {
		int count = 0;
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				auto cell = &cells[x][y];
				if (cell.owner == 0) {
					Vec2[64] buffer2;
					if (findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(-1, -1), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2( 0, -1), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(+1, -1), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(-1,  0), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(+1,  0), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(-1, +1), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2( 0, +1), owner, buffer2).length > 0 ||
						findCellsIsAbleToTurnDir(Vec2(x, y), Vec2(+1, +1), owner, buffer2).length > 0
					) {
						buffer[count++] = Vec2(x, y);
					}
				}
			}
		}
		return buffer[0..count];
	}

	int getCountOfOwnersCell(int owner) {
		int count = 0;
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				auto cell = &cells[x][y];
				if (cell.owner == owner) {
					count++;
				}
			}
		}
		return count;
	}
}
