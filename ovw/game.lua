Game = class()

function Game:load()
  devMode = false

  self.view = View()
  self.collision = Collision()
  self.hud = Hud()
  self.house = House()
  self.player = Player()
  self.spells = Manager()
  self.particles = Manager()
  self.enemies = Manager()
  self.pickups = Manager()
  self.boss = nil

  WeightedLoot = WeightedRandom(
  {
      {Glowstick, .25},
      {FirstAidKit, .2},
      {Ammo, .7},
      {Torch, .1}}, 1.25)

  WeightedLootSizes = WeightedRandom(
  {{1, .5}, {2, .2}, {3, .05}, {4, .01}}, 0.76)

  makeLootTable = function() return WeightedLoot:pick((WeightedLootSizes:pick(1))[1]) end

  self.house:spawnEnemies()
  self.house:spawnItems()
end

function Game:update()
  self.house:update()
  self.player:update()
  self.spells:update()
  self.particles:update()
  self.enemies:update()
  self.pickups:update()
  if self.boss then self.boss:update() end
  self.collision:resolve()
  self.view:update()
  self.hud.fader:update()
end

function Game:draw()
  self.view:draw()
end

function Game:restart()
  Overwatch:remove(ovw)
  Overwatch:add(Game)
end

function Game:keypressed(key)
  if key == 'escape' then love.event.quit()
  elseif key == '`' then devMode = not devMode end
  self.player:keypressed(key)
end

function Game:mousepressed(...)
  self.view:mousepressed(...)
  self.player:mousepressed(...)
  self.hud:mousepressed(...)
end
