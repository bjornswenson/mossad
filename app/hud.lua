Hud = class()

local g = love.graphics
local w, h = g.width, g.height

function Hud:init()
  self.font = love.graphics.newFont('media/fonts/pixel.ttf', 8)
  self.fader = Fader()
  ovw.view:register(self)
end

function Hud:gui()
  g.setFont(self.font)
  self:blood()
  self:items()
  self.fader:gui()
  self:debug()
end

function Hud:blood() -- Yo sach a hudblood, haarry
  local p = ovw.player
  local amt = 1 - (p.iNeedHealing / p.iNeedTooMuchHealing)
  local alpha = math.max(1 - (tick - p.lastHit) * tickRate, 0) / 6
  alpha = math.min(alpha * 100, 100)
  g.setColor(80, 0, 0, alpha)
  g.rectangle('fill', 0, 0, w(), h())
end

function Hud:items()
  local size = 40
  for i = 1, 5 do
    local item = ovw.player.inventory.items[i]
    local alpha = not item and 80 or (ovw.player.inventory.selected == i and 255 or 160)
    g.setColor(255, 255, 255, alpha)
    g.rectangle('line', 2 + (size + 2) * (i - 1) + .5, 2 + .5, size, size)
    if item then
      local str = item.name
      if item.stacks then str = item.stacks .. ' ' .. str end
      g.print(str, 2 + (size + 2) * (i - 1) + .5 + 4, 2 + .5 + 1)
    end
  end
  if ovw.player.ammo == 0 then g.setColor(255, 0, 0)
  else g.setColor(255, 255, 255) end
  g.print('ammo: ' .. ovw.player.ammo, 2, size + 3)
end

function Hud:debug()
  if not debug then return end
  g.setColor(255, 255, 255)
  g.print(love.timer.getFPS() .. 'fps ' .. (ovw.view.scale * 100) .. '%', 1, h() - g.getFont():getHeight())
end

