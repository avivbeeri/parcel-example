import "math" for Vec, M
import "graphics" for ImageData, Canvas, Color, Font
import "input" for Keyboard, Mouse

import "./core/scene" for View
import "./core/display" for Display
import "./core/config" for Config
var DEBUG = Config["debug"]

import "./extra/palette" for EDG32, EDG32A
import "./entity/all" for Player
import "./extra/events" for CollisionEvent,
  EntityRemovedEvent,
  EntityAddedEvent,
  MoveEvent,
  AttackEvent,
  ModifierEvent

class AsciiRenderer is View {
  construct new(parent, args) {
    super(parent)

    _camera = Vec.new()
    _world = args[0]
    var player = _world.active.getEntityByTag("player")
    _playerId = player.id

    var scale = 1
    _tileSizeX = 8
    _tileSizeY = 8
    _tileSize =  Vec.new(_tileSizeX, _tileSizeY)
    _camera.x = player.pos.x * _tileSizeX
    _camera.y = player.pos.y * _tileSizeY
    _offsetX = 0
    _lastPosition = player.pos
    _entityLerpBatch = null
  }

  world { _world }
  camera { _camera }
  camera=(v) { _camera = v }

  update() {
    super.update()
    _zone = _world.active

    var player = _zone.getEntityByTag("player")
    if (player) {
      _lastPosition = player.pos
    }

    if (player) {
      var mouse = Mouse.pos
      var mouseEntities = _zone.getEntitiesAtTile(screenToWorld(mouse))
      if (mouseEntities.count > 0) {
        top.store.dispatch({ "type": "selection", "ids": [ mouseEntities.toList[0].id ] })
      } else {
        top.store.dispatch({ "type": "selection", "ids": [] })
      }
    }
  }

  process(event) {
    super.process(event)
  }

  busy { false }

  tileSize { _tileSize }

  draw() {
    _zone = _world.active
    var player = _zone.getEntityByTag("player")
    Canvas.cls(Display.bg)

    var cx = center.x
    var cy = center.y

    _camera.x = _lastPosition.x * _tileSize.x
    _camera.y = _lastPosition.y * _tileSize.y

    Canvas.offset((cx - _camera.x).floor, (cy - _camera.y).floor)

    var xRange = M.max((cx / _tileSizeX), (Canvas.width - cx) / _tileSizeX).ceil + 1
    var yRange = M.max((cy / _tileSizeY), (Canvas.height - cy) / _tileSizeY).ceil + 1
    for (dy in -yRange..yRange) {
      for (dx in -xRange..xRange) {
        var x = dx
        var y = dy
        var sx = x * _tileSizeX + _offsetX
        var sy = y * _tileSizeY
        var tile = _zone.map[x, y]

        var floor = tile["floor"]
        tile["dirty"] = false
        if (floor == "tile") {
          Canvas.print(" ", sx, sy, EDG32[23])
        } else if (floor == "wall") {
          Canvas.print("#", sx, sy, EDG32[23])

        }
      }
    }

    for (entity in _zone.entities) {
      if (isOnScreen(entity.pos)) {
        var x = entity.pos.x
        var y = entity.pos.y
        var sx = x * _tileSizeX + _offsetX
        var sy = y * _tileSizeY
        Canvas.print(entity.name[0], sx, sy, EDG32[14])
      }
    }

    // This will draw all the children
    super.draw()
    Canvas.offset()
  }

  center {
    var cx = (Canvas.width - _offsetX - 20) / 2
    var cy = (Canvas.height - _tileSizeY) / 2
    return Vec.new(cx, cy)
  }

  screenToWorld(pos) {
    var tile =  (pos - (center - _camera))
    tile.x = (tile.x / _tileSizeX).floor
    tile.y = (tile.y / _tileSizeY).floor
    return tile
  }

  worldToScreen(pos) {
    var screenPos = pos * 1
    screenPos.x = screenPos.x * _tileSizeX
    screenPos.y = screenPos.y * _tileSizeY
    return (screenPos) + (center - _camera)
  }

  isOnScreen(worldPos) {
    var screenPos = worldToScreen(worldPos)
    return (screenPos.x >= 0 && screenPos.x < Canvas.width && screenPos.y >= 0 && screenPos.y < Canvas.height)
  }
}
