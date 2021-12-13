#!/bin/bash
dome nest -co game.egg -- *.wren core extra entity scene system res/font res/img config.json tileRules.json
cp game.egg ~/Downloads/dome-builds/cartomancer
