Arsenal = class()

function Arsenal:init()
  self.weapons = {}
  self.selected = nil
  self.startingWeapon = false
end

function Arsenal:update()
  --if self.selected then self:select(self.selected) end
  table.with(self.weapons, 'update')
end

function Arsenal:keypressed(...)
  if self.weapons[self.selected] then self.weapons[self.selected]:keypressed(...) end
end

function Arsenal:mousepressed(x, y, b)
  if self.selected then
    if b == 'r' then
      if not love.keyboard.isDown('tab') then  self.weapons[self.selected]:melee() end
    elseif b == 'wu' and self.selected > 1 then
      self:select(self.selected - 1)
    elseif b == 'wd' and self.selected < #self.weapons then
      self:select(self.selected + 1)
    end
  end
end

function Arsenal:add(weapon)
  if weapon.type == 'Weapon' then
    local stacks = weapon.stacks
    if stacks then
      for i = 1, #self.weapons do
        if self.weapons[i].name == weapon.name then
          self.weapons[i].stacks = self.weapons[i].stacks + stacks
          return true
        end
      end
    end
    if not self.startingWeapon then ovw.house:openRoom(ovw.player.room) end
    if #self.weapons < 2 then
      table.insert(self.weapons, weapon)
      weapon.index = #self.weapons
      if not self.selected then self:select(#self.weapons) end
      return true
    end
  end
  return false
end

function Arsenal:remove(index)
  local weapon = self.weapons[index]
  if weapon then
    if weapon.stacks then
      weapon.stacks = weapon.stacks - 1
      if weapon.stacks > 0 then
        local sel = weapon.selected
        f.exe(weapon.init, weapon)
        weapon.selected = sel
        return
      end
    end
    weapon:destroy()
    table.remove(self.weapons, index)
    while not self.weapons[self.selected] do
      self.selected = self.selected - 1
    end
    self:select(self.selected)
  end
end

function Arsenal:drop(index)
  index = index or self.selected
  local weapon = self.weapons[index]
  if weapon then
    weapon.selected = false
    f.exe(weapon.drop, weapon)
    Pickup({
      x = ovw.player.x,
      y = ovw.player.y,
      dirty = true,
      weapon = weapon
    })
    table.remove(self.weapons, index)
    while not self.weapons[self.selected] do
      self.selected = self.selected - 1
    end
    self:select(self.selected)
  end
end

function Arsenal:select(index)
  local old, new = self.weapons[self.selected], self.weapons[index]
  self.selected = index
  if old then
    old.selected = false
    f.exe(old.deselect, old) --UNUSED
  end

  if new then
    new.selected = true
    f.exe(new.select, new) --UNUSED
  end
end
