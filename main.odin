package main

import gameFunc "/lib"

main :: proc() {

	game := gameFunc.initGame()

	gameFunc.runLoop(&game)
}