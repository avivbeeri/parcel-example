import "./core/rng" for RNG

class GameEndCheck {
  static update(ctx) {
    if (ctx.parent.gameover) {
      return
    }
    var player = ctx.getEntityByTag("player")
    if (!player || !player.alive) {
      ctx.events.add(GameEndEvent.new(false))
      ctx.parent.gameover = true
    } else if (!ctx.entities.any {|entity| entity is Collectible || (entity is Creature && entity["types"].contains("enemy")) }) {
      ctx.events.add(GameEndEvent.new(true))
      ctx.parent.gameover = true
    }
  }
}

class RemoveDefeated {
  static update(ctx) {
    ctx.entities
    .where {|entity| entity.has("stats") && entity["stats"].get("hp") <= 0 }
    .each {|entity|
      entity.alive = false
      if (entity.has("loot") && !entity["loot"].isEmpty) {
        System.print("dropping loot")
        System.print(entity["loot"])
        var loot = RNG.sample(entity["loot"])
        var lootEntity = ctx.addEntity(Collectible.new(loot))
        lootEntity.pos = entity.pos
      }
    }
  }
}

import "./extra/events" for GameEndEvent
import "./entity/collectible" for Collectible
import "./entity/creature" for Creature
