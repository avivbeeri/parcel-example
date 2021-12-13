import "input" for Keyboard
import "graphics" for Canvas, Color, Font
import "./core/scene" for Scene

class StartScene is Scene {
  construct new(args) {
    super()
    Font.load("quiver64", "res/font/Quiver.ttf", 64)
    Font.load("quiver16", "res/font/Quiver.ttf", 16)
    _title = "Parcel"
    var size = Font["quiver64"].getArea(_title)
    _x = (Canvas.width - size.x) / 2
    _y = 32
    Font.load("m5x7", "res/font/m5x7.ttf", 16)
    size = Font["m5x7"].getArea("Press SPACE to begin")
    _helpX = (Canvas.width - size.x) / 2
    _fill = EDG32[17]
    _border = EDG32[16]
  }

  update() {
    if (Keyboard["space"].justPressed) {
      game.push(WorldScene, [ WorldGenerator.generate() ])
      return
    }
  }

  draw() {
    Canvas.cls(Display.bg)
    var s = 4
    for (y in -s..s) {
      for (x in -s..s) {
        Canvas.print(_title, _x + x, _y + y, _border, "quiver64")
      }
    }
    Canvas.print(_title, _x, _y, _fill, "quiver64")
    Canvas.print("Press SPACE to begin", _helpX, Canvas.height - 32, Color.white, "m5x7")
  }
}

import "./core/display" for Display
import "./extra/palette" for EDG32
import "./generator" for WorldGenerator
import "./scene/game" for WorldScene
