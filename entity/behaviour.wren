import "math" for Vec

import "./core/action" for Action
import "./core/config" for Config
import "./core/dir" for NSEW

import "./extra/combat" for Attack, AttackType
import "./extra/actions" for MoveAction, AttackAction
import "./core/rng" for RNG
import "./core/behaviour" for Behaviour


class WaitBehaviour is Behaviour {
  construct new(self) {
    super(self)
    self["seenPlayer"] = false
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    var room = map[self.pos]["room"]
    if (self["seenPlayer"]) {
      return null
    }
    if (room && room.contains(player.pos)) {
      self["seenPlayer"] = true
      return null
    } else {
      var search = player["dijkstra"]
      var path = DijkstraMap.reconstruct(search[0], player.pos, self.pos)
      if (path && path.count < 2 + 2) {
        self["seenPlayer"] = true
        return null
      }
    }
    var dir = RNG.sample(NSEW.values.toList)
    if (dir) {
      return MoveAction.new(dir, true, Action.none )
    } else {
      return Action.none
    }
  }
}


class SeekBehaviour is Behaviour {
  construct new(self) {
    super(self)
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    System.print(player)
    if (player) {
      var search = player["dijkstra"]
      var path = DijkstraMap.reconstruct(search[0], player.pos, self.pos)
      if (path == null) {
        return Action.none
      }
      return MoveAction.new(path[1] - self.pos, true)
    }
    return Action.none
  }
}

class RangedBehaviour is Behaviour {
  construct new(self, range) {
    super(self)
    _maxRange = range
  }
  construct new(self, range, factory) {
    super(self)
    _maxRange = range
    _factory = factory
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    if (player) {
      if (player.pos.x == self.pos.x || player.pos.y == self.pos.y) {
        // Same x or y coordinate
        var range = (player.pos - self.pos)
        if (range.manhattan < _maxRange) {
          // In range
          // check LOS
          var solid = false
          var unit = range.unit
          for (step in 0..range.manhattan) {
            var tile = self.pos + unit * step
            if (ctx.isSolidAt(tile)) {
              solid = true
              break
            }
          }
          if (!solid) {
            // attack is good
            if (!_factory) {
              return AttackAction.new(player.pos, Attack.new(self["stats"].get("spi"), AttackType.lightning, false))
            } else {
              return _factory.call(player)
            }
          }
        }
      }
    }
  }
}

import "./factory" for EntityFactory
import "./core/graph" for WeightedZone, BFS, AStar, DijkstraMap
