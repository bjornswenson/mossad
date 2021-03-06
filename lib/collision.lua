local hardon = require 'lib/hardon'

Collision = class()
Collision.cellSize = 32

function Collision:init()
  local function onCollide(dt, a, b, dx, dy)
    a, b = a.owner, b.owner
    f.exe(a.collision.with and a.collision.with[b.tag], a, b, dx, dy)
    f.exe(b.collision.with and b.collision.with[a.tag], b, a, -dx, -dy)
  end
  
  self.hc = hardon(self.cellSize, onCollide)
  self.depth = -100
  ovw.view:register(self)
end

function Collision:draw()
  if devMode then
    self.depth = -100
    local rect = {
      ovw.view.x,
      ovw.view.y,
      ovw.view.x + ovw.view.w,
      ovw.view.y + ovw.view.h
    }
    for shape in pairs(self.hc:shapesInRange(unpack(rect))) do
      love.graphics.setColor(255, 255, 255, 50)
      shape:draw('fill')
      love.graphics.setColor(255, 255, 255)
      shape:draw('line')
    end
  else
    self.depth = -1
    local rect = {
      ovw.view.x,
      ovw.view.y,
      ovw.view.x + ovw.view.w,
      ovw.view.y + ovw.view.h
    }
    for shape in pairs(self.hc:shapesInRange(unpack(rect))) do
      if shape.owner and shape.owner.tag and shape.owner.tag == 'wall' then
        love.graphics.setColor(0, 0, 0, 255)
        shape:draw('fill')
      end
    end
  end
end

function Collision:resolve()
  self.hc:update(tickRate)
end

function Collision:update() --just a naming scenario
  self:resolve()
end

function Collision:register(obj)
  local shape
  if obj.collision.shape == 'rectangle' then
    shape = self.hc:addRectangle(obj.x, obj.y, obj.width, obj.height)
  elseif obj.collision.shape == 'circle' then
    shape = self.hc:addCircle(obj.x, obj.y, obj.radius)
  end

  if obj.collision.static then
    self.hc:setPassive(shape)
  end

  obj.shape = shape
  shape.owner = obj

  return shape
end

function Collision:unregister(obj)
  self.hc:remove(obj.shape)
end

function Collision:pointTest(x, y, tag, all)
  local res = all and {} or nil
  for _, shape in pairs(self.hc:shapesAt(x, y)) do
    if (not tag) or shape.owner.tag == tag then
      if all then table.insert(res, shape.owner)
      else res = shape.owner break end
    end
  end
  return res
end

function Collision:lineTest(x1, y1, x2, y2, tag, all, first)
  local res = all and {} or nil
  local dis = math.distance(x1, y1, x2, y2)
  local mindis = first and math.huge or nil
  local _x1, _y1 = math.min(x1, x2), math.min(y1, y2)
  local _x2, _y2 = math.max(x1, x2), math.max(y1, y2)
  for shape in pairs(self.hc:shapesInRange(_x1, _y1, _x2, _y2)) do
    if (not tag) or shape.owner.tag == tag then
      local intersects, d = shape:intersectsRay(x1, y1, x2 - x1, y2 - y1)
      if intersects and d >= 0 and d <= 1 then
        if not first then
          if all then table.insert(res, shape.owner)
          else res = shape.owner break end
        elseif d * dis < mindis then
          mindis = d * dis
          res = shape.owner
        end
      end
    end
  end
  
  return res, mindis
end

function Collision:arcTest(x, y, r, dir, theta, tag, all, first)
  local res = all and {} or nil
  local mindis = first and math.huge or nil
  local x2, y2 = x + math.cos(dir) * r, y + math.sin(dir) * r
  local _x1, _y1 = math.min(x, x2), math.min(y, y2)
  local _x2, _y2 = math.max(x, x2), math.max(y, y2)
  for _, shape in pairs(self.hc:shapesInRange(_x1, _y1, _x2, _y2)) do
    if (not tag) or shape.owner.tag == tag then
      local angle = math.direction(x, y, shape:center()) --angle from source to shape
      --normalize the angle
      if dir < -math.pi / 2 and angle > 0 then angle = angle - math.pi * 2 end
      if dir > math.pi / 2 and angle < 0 then angle = angle + math.pi * 2 end

      if angle >= dir - theta / 2 and angle <= dir + theta / 2 then
        --inside the angle
        if not first then
          if all then table.insert(res, shape.owner)
          else res = shape.owner break end
        elseif d * r < mindis then
          mindis = d * r
          res = shape.owner
        end
      elseif angle < dir - theta / 2 then
        local intersects, d = shape:intersectsRay(x, y, math.cos(dir - theta / 2) * r, math.sin(dir - theta / 2) * r)
        if intersects and d >= 0 and d <= 1 then
          --inside the angle
          if not first then
            if all then table.insert(res, shape.owner)
            else res = shape.owner break end
          elseif d * r < mindis then
            mindis = d * r
            res = shape.owner
          end
        end
      elseif angle > dir + theta / 2 then
        local intersects, d = shape:intersectsRay(x, y, math.cos(dir + theta / 2) * r, math.sin(dir + theta / 2) * r)
        if intersects and d >= 0 and d <= 1 then
          --inside the angle
          if not first then
            if all then table.insert(res, shape.owner)
            else res = shape.owner break end
          elseif d * r < mindis then
            mindis = d * r
            res = shape.owner
          end
        end
      end
    end
  end

  return res, mindis
end

--- EXTEND hc

function Collision:addDiamond(x,y,w,h)
  return self.hc:addPolygon(x+math.round(w/2),y, x+w,y+math.round(h/2), x+math.round(w/2),y+h, x,y+math.round(h/2))
end