import "math" for Vec, M

import "core/world" for World, Zone
import "core/map" for TileMap, Tile
import "core/director" for
  ActionStrategy,
  TurnBasedStrategy,
  EnergyStrategy

import "./core/config" for Config
import "./core/rng" for RNG

import "extra/roomGenerator" for GrowthRoomGenerator, Room
import "logic" for RemoveDefeated, GameEndCheck

var SPAWN_DIST = [ 2 ]
var SPAWNABLES = Config["entities"].where {|config| config["types"].contains("spawnable") }.toList
var ROOM_COUNT = 4

class WorldGenerator {
  static generate() {
    return TestGenerator.generate()
    // return GrowthGenerator.init().generate()
  }
}

class GrowthGenerator {
  static generate() {
    return GrowthGenerator.init().generate()
  }

  construct init() {}
  generate() {

    // 1. Generate map
    // 2. Populate with enemies
    // 3. Select starting deck (based on steps 1 and 2)

    var world = World.new(EnergyStrategy.new())
    var zone = world.pushZone(Zone.new(TileMap.init()))
    zone.map.default = { "solid": true, "floor": "void", "index": -1, "dirty": false }

    // Order is important!!
    // Put postUpdate here
    zone.postUpdate.add(RemoveDefeated)
    zone.postUpdate.add(GameEndCheck)
    // -------------------

    var generated = GrowthRoomGenerator.generate()
    var rooms = generated[0]
    var doors = generated[1]

    var start = rooms[0]
    var player = zone.addEntity("player", Player.new())
    player.pos = Vec.new(start.x + 1, start.y + 1)

    var enemyCount = 0
    for (room in rooms) {
      var wx = room.x
      var wy = room.y
      var width = wx + room.z
      var height = wy + room.w
      for (y in wy...height) {
        for (x in wx...width) {
          if (x == wx || x == width - 1 || y == wy || y == height - 1) {
            zone.map[x, y] = Tile.new({ "floor": "wall", "solid": true, "room": room })
          } else {
            zone.map[x, y] = Tile.new({ "floor": "tile", "room": room })
          }
        }
      }

      var spawnTotal = RNG.sample(SPAWN_DIST)

      for (i in 0...spawnTotal) {
        var entity = EntityFactory.prepare(SPAWNABLES[RNG.int(SPAWNABLES.count)])
        spawnIn(zone, room, entity)
        enemyCount = enemyCount + 1
      }
    }
    if (enemyCount == 0) {
      var room = rooms[-1]
      var entity = EntityFactory.prepare(SPAWNABLES[RNG.int(SPAWNABLES.count)])
      spawnIn(zone, room, entity)
    }
    for (door in doors) {
      zone.map[door.x, door.y] = Tile.new({ "floor": "tile" })
    }

    return world
  }

  spawnIn(zone, room, entity) {
    var wx = room.x
    var wy = room.y
    var width = wx + room.z
    var height = wy + room.w
    zone.addEntity(entity)
    var spawn = Vec.new(RNG.int(wx + 1, width - 1), RNG.int(wy + 1, height - 1))
    // TODO: Can land on player?
    while (zone.getEntitiesAtTile(spawn).count >= 1 || (zone.isSolidAt(spawn))) {
      spawn = Vec.new(RNG.int(wx + 1, width - 1), RNG.int(wy + 1, height - 1))
    }
    entity.pos = spawn
    entity.priority = RNG.int(13)
  }
}


class TestGenerator {
  static generate() {
    // World generation code

    var world = World.new(EnergyStrategy.new())
    var zone = world.pushZone(Zone.new(TileMap.init()))
    zone.map.default = { "solid": true, "floor": "void", "index": -1, "dirty": false }

    // Order is important!!
    // Put postUpdate here
    zone.postUpdate.add(RemoveDefeated)
    zone.postUpdate.add(GameEndCheck)
    // -------------------

    var width = 10
    var height = 10
    var room = Room.new(0, 0, width, height)
    for (y in 0..height) {
      for (x in 0..width) {
        if (x == 0 || x == width || y == 0 || y == width) {
          zone.map[x, y] = Tile.new({ "floor": "wall", "solid": true, "room": room })
        } else {
          zone.map[x, y] = Tile.new({ "floor": "tile", "room": room })
        }
      }
    }


    var player = zone.addEntity("player", Player.new())
    player.pos = Vec.new(5, 5)
    var entity = EntityFactory.prepare(SPAWNABLES[RNG.int(SPAWNABLES.count)])
    entity.pos = Vec.new(9, 9)
    zone.addEntity(entity)

    return world
  }
}

import "./entity/player" for Player
import "factory" for EntityFactory
