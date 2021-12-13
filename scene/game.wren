import "graphics" for ImageData, Canvas, Color, Font
import "input" for Keyboard, Mouse
import "math" for Vec, M

import "./core/dataobject" for Store, Reducer
import "./core/scene" for Scene, View, State
import "./core/config" for Config
var DEBUG = Config["debug"]

import "./keys" for InputActions
import "./extra/events" for GameEndEvent, LogEvent
import "./extra/actions" for MoveAction, RestAction
import "./entity/all" for Player
import "./extra/widgets" for Button


class WaitState is State {
  construct new(ctx, view) {
  }
  tickWorld { false }
}

class SelectionState is State {
  construct new(ctx, view) {
    _ctx = ctx
    _view = view
  }
  onEnter() {
    _closeButton = Button.new("X", Vec.new(460, 22), Vec.new(15, 15))
    _view.addViewChild(_closeButton)
    var player = _ctx.active.getEntityByTag("player")
    var entities = _ctx.active.entities[0..-1].sort {|a, b|
      return (a.pos - player.pos).length < (b.pos - player.pos).length
    }
    _targets = entities.where {|entity|
      return entity.has("types") && (entity.pos - player.pos).length < 10 //view.isOnScreen(entity.pos)
    }.toList
    _current = (_targets.count > 1 && _targets[0].id == player.id) ? 1 : 0
  }

  update() {
    if (_closeButton.clicked || InputActions.cancel.justPressed) {
      return PlayState.new(_ctx, _view)
    }
    if (InputActions.nextTarget.justPressed) {
      _current = _current + 1
    }
    _current = _current % _targets.count
    var selection = _view.top.store.state["selected"]
    _view.top.store.dispatch({ "type": "selection", "ids": [ _targets[_current].id ] })
    return this
  }

  onExit() {
    _view.removeViewChild(_closeButton)
    _view.store.dispatch({ "type": "selection", "ids": [] })
  }
}

class PlayState is State {
  construct new(ctx, view) {
    _ctx = ctx
    _view = view
  }

  update() {
    var player = _ctx.active.getEntityByTag("player")
    var allowInput = !_view.busy && (_ctx.strategy.currentActor is Player) && _ctx.strategy.currentActor.priority >= 12

    if (player && allowInput) {
      // Do UI things?
    }
    if (!player) {
      return WaitState.new(_ctx, _view)
    }
    // Allow movement
    if (!player.action && allowInput) {
      if (InputActions.nextTarget.justPressed) {
        return SelectionState.new(_ctx, _view)
      }
      if (InputActions.rest.firing) {
        player.action = RestAction.new()
      } else {
        var move = Vec.new()
        if (InputActions.left.firing) {
          move.x = -1
        } else if (InputActions.right.firing) {
          move.x = 1
        } else if (InputActions.up.firing) {
          move.y = -1
        } else if (InputActions.down.firing) {
          move.y = 1
        }
        if (move.length > 0) {
          player.action = MoveAction.new(move)
        }
      }
    }
    return this
  }
}

class WorldReducer is Reducer {
  construct new() {}
  reduce(state, action) {
    if (action["type"] == "selection") {
      state["selected"] = action["ids"]
    }
    return state
  }
}

class WorldScene is Scene {
  construct new(args) {
    super()
    _world = args[0]
    _zone = _world.active
    store = Store.create({ "selected": [] }, WorldReducer.new())
    addViewChild(AsciiRenderer.new(this, args))
    _pending = []
    _state = PlayState.new(_world, this)
  }

  world { _world }

  update() {
    _zone = _world.active

    super.update()

    if (!busy) {
      _pending.each {|view| addViewChild(view) }
      _pending.clear()
    }

    var state = _state.update()
    if (state != _state) {
      changeState(state)
    }
    if (!state.tickWorld) {
      return
    }

    _world.update()

    for (event in _zone.events) {
      process(event)
    }
  }

  changeState(newState) {
    _state.onExit()
    _state = newState
    _state.onEnter()
  }

  draw() {
    super.draw()
  }

  process(event) {
    super.process(event)
    if (event is GameEndEvent) {
      var result = event.won ? "won" : "lost"
      System.print("The game has ended. You have %(result).")
      _pending.add(ResetMessage.new(this, _world))
      changeState(WaitState.new(_world, this))
    } else if (event is LogEvent) {
      System.print(event.text)
    }
  }
}

import "./scene/renderer" for AsciiRenderer
import "./scene/views" for ResetMessage
