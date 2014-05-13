Game = class()

function Game:load()
  debug = false
  self.restartTimer = 0

  self.view = View()
  self.hud = Hud()
  self.collision = Collision()
  self.house = House()
  self.player = Player()
  self.spells = Manager()
  self.particles = Manager()
  self.enemies = Manager()
  self.boss = nil

  self.house:spawnEnemies()
end

function Game:update()
  self.house:update()
  self.player:update()
  self.spells:update()
  self.particles:update()
  self.enemies:update()
  if self.boss then self.boss:update() end
  self.collision:resolve()
  self.view:update()
  self.hud.fader:update()
  self.restartTimer = timer.rot(self.restartTimer, function()
    Overwatch:remove(ovw)
    Overwatch:add(Game)
  end)
end

function Game:draw()
  self.view:draw()
end

function Game:keypressed(key)
  if key == 'escape' then love.event.quit()
  elseif key == '`' then debug = not debug end
  self.player:keypressed(key)
end

function Game:mousepressed(...)
  self.view:mousepressed(...)
  self.player:mousepressed(...)
end
