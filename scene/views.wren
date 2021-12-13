import "input" for Keyboard, Mouse
import "graphics" for ImageData, Canvas, Color, Font
import "math" for M, Vec
import "./core/display" for Display
import "./core/scene" for UiView
import "./keys" for InputActions
import "./extra/palette" for EDG32, EDG32A

var Bg = EDG32[2]
var Red = EDG32[26]

class ResetMessage is UiView {
  construct new(parent, ctx) {
    super(parent, ctx)
  }

  update() {
    if (InputActions.confirm.justPressed) {
      top.game.push(WorldScene, [ WorldGenerator.generate() ])
    }
  }

  draw() {
    Canvas.rectfill(20, 20, Canvas.width - 40, Canvas.height - 40, Bg)
    var area = Display.printCentered("Game Over", 30, Color.black, "quiver64")
    Display.printCentered("This is a reset point", 30 + area.y + 40, Color.black, "m5x7")

    Display.printCentered("Press SPACE to play again.", Canvas.height - 40, Color.black, "m5x7")
  }
}


import "./generator" for WorldGenerator
import "./scene/game" for WorldScene
