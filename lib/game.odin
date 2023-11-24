package game

import SDL "vendor:sdl2"
import "core:math/rand"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

SPEED :: 400

Paddle :: struct {
	height: f16,
	width: f16,
	color: SDL.Color,
	x: i32,
	y: i32,
	mDownSpeed: f32,
	mUpSpeed: f32
}

Vector :: struct {
	x: f32,
	y: f32
}

Ball :: struct {
	height: f16,
	width: f16,
	color: SDL.Color,
	x: i32,
	y: i32,
	vector: Vector
}

Game :: struct {
	mWindow: ^SDL.Window,
	mRenderer: ^SDL.Renderer,
	mIsRunning: bool,
	mPlayer: Paddle,
	mEnemy: Paddle,
	mBall: Ball,
	mTicksCount: u32
}

initGame :: proc() -> Game {
	window := SDL.CreateWindow("Odin sdl", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL.WINDOW_SHOWN);
	renderer := SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC)
	color := SDL.Colour{254, 254, 254, 0}
	player := Paddle{120, 12, color, 20, WINDOW_HEIGHT/2, 0.0, 0.0}
	enemy := Paddle{120, 12, color, 1280-30, WINDOW_HEIGHT/2, 0.0, 0.0}
	ball := Ball{10, 10, color, WINDOW_WIDTH/2-6, WINDOW_HEIGHT/2 + 3, Vector{-700, 0}}
	game := Game{window, renderer, true, player, enemy, ball, SDL.GetTicks()}
	return game
}

drawPaddles :: proc(renderer: ^SDL.Renderer, paddle: Paddle) {
	rect := SDL.Rect{paddle.x, paddle.y, i32(paddle.width), i32(paddle.height)}
	SDL.SetRenderDrawColor(renderer, paddle.color.r, paddle.color.g, paddle.color.b, paddle.color.a)
	SDL.RenderFillRect(renderer, &rect)
}

drawBall :: proc(renderer: ^SDL.Renderer, ball: Ball) {
	rect := SDL.Rect{ball.x, ball.y, i32(ball.width), i32(ball.height)}
	SDL.RenderFillRect(renderer, &rect)
	
}

runLoop :: proc(game: ^Game) {
	loop: for game.mIsRunning {
		processInput(game)
		updateGame(game)
		generateOutput(game)
	}
	shutdown(game)
}

shutdown :: proc(game: ^Game) {
	SDL.DestroyWindow(game.mWindow)
}

processInput :: proc(game: ^Game) {
	event: SDL.Event;
	for (SDL.PollEvent(&event)) {
		#partial switch event.type {
			case .QUIT: game.mIsRunning = false
		}
	}
	state := SDL.GetKeyboardState(nil)
	if bool(state[SDL.Scancode.ESCAPE]) {
		game.mIsRunning = false
	}
	processState(&game.mPlayer, state)
	processEnemyState(game)
}

processEnemyState :: proc(game: ^Game) {
	game.mEnemy.mDownSpeed = 0
	game.mEnemy.mUpSpeed = 0
	if game.mBall.y < game.mEnemy.y {
		game.mEnemy.mUpSpeed += f32(SPEED)
	}
	else if game.mBall.y > game.mEnemy.y + i32(game.mEnemy.height) {
			game.mEnemy.mDownSpeed += f32(SPEED)
	}
}

processState :: proc(player: ^Paddle, state: [^]u8) {
	player.mDownSpeed = f32(0)
	player.mUpSpeed = f32(0)
	if bool(state[SDL.Scancode.W]) {
		player.mUpSpeed += f32(SPEED)
	}
	if bool(state[SDL.Scancode.S]) {
		player.mDownSpeed += f32(SPEED)
	}
}

movePlayer :: proc(game: ^Game, deltaTime: f32) {
	game.mPlayer.y += i32(game.mPlayer.mDownSpeed * deltaTime)
	game.mPlayer.y -= i32(game.mPlayer.mUpSpeed * deltaTime)
}

moveBall :: proc(game: ^Game, deltaTime: f32) {
	if (inBounds(game.mPlayer, game.mBall) || inEnemyBounds(game.mEnemy, game.mBall)) {
		game.mBall.vector.x *= -1
		game.mBall.vector.y = rand.float32_range(-500, 500)
	}
	if game.mBall.y <= 0 || game.mBall.y >= WINDOW_HEIGHT - i32(game.mBall.height) {
		game.mBall.vector.y *= -1
	}
	game.mBall.x += i32(game.mBall.vector.x * deltaTime)
	game.mBall.y += i32(game.mBall.vector.y * deltaTime)
}

inBounds :: proc(paddle: Paddle, ball: Ball) -> bool {
	return (ball.y >= paddle.y && ball.y <= paddle.y + i32(paddle.height) &&
			ball.x >= paddle.x && ball.x <= paddle.x + i32(paddle.width))
}

inEnemyBounds :: proc(paddle: Paddle, ball: Ball) -> bool {
	return (ball.y >= paddle.y && ball.y <= paddle.y + i32(paddle.height) &&
			ball.x >= paddle.x - i32(ball.width) && ball.x < paddle.x)
}

moveEnemy :: proc(game: ^Game, deltaTime: f32) {
	game.mEnemy.y += i32(game.mEnemy.mDownSpeed * deltaTime)
	game.mEnemy.y -= i32(game.mEnemy.mUpSpeed * deltaTime)
}

resetGame :: proc(game: ^Game) {
	if game.mBall.x < -200 || game.mBall.x > 1420 {
		if game.mBall.vector.x < 0 {
			game.mBall.x = 450 + (WINDOW_WIDTH/2) - 6
		}
		else {
			game.mBall.x = (WINDOW_WIDTH/2) - 6 - 450
		}
		game.mBall.vector.y = 0
		game.mPlayer.y = WINDOW_HEIGHT/2
		game.mEnemy.y = WINDOW_HEIGHT/2
	}
}

updateGame :: proc(game: ^Game) {
	for (!SDL.TICKS_PASSED(SDL.GetTicks(), game.mTicksCount + 16)) {
		};

	deltaTime: f32 = f32(SDL.GetTicks() - game.mTicksCount) / 1000.0
	if deltaTime > 0.05 {
		deltaTime = 0.05
	}
	game.mTicksCount = SDL.GetTicks()
	movePlayer(game, deltaTime)
	moveEnemy(game, deltaTime)
	moveBall(game, deltaTime)
	resetGame(game)
}

generateOutput :: proc(game: ^Game) {
	SDL.SetRenderDrawColor(game.mRenderer, 0, 0, 0, 0)
	SDL.RenderClear(game.mRenderer)
	drawPaddles(game.mRenderer, game.mPlayer)
	drawPaddles(game.mRenderer, game.mEnemy)
	drawBall(game.mRenderer, game.mBall)
	
	SDL.RenderPresent(game.mRenderer)
}

