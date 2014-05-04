local hardon = require 'lib/hardon'

require 'app/house/room'
require 'app/house/roomRectangle'

local function randomFrom(t)
  if #t == 0 then return end
  return t[love.math.random(1, #t)]
end

House = class()
House.cellSize = 32

function House:init()
  self.roomTypes = {RoomRectangle}
  self.rooms = {}
  self.roomSpacing = 1

  self.grid = {}

  self:generate()

  self.depth = 5
  self.drawTiles = true
  ovw.view:register(self)

  self.tileImage = love.graphics.newImage('media/graphics/newTiles.png')
  local w, h = self.tileImage:getDimensions()
  local function t(x, y) return love.graphics.newQuad(1 + (x * 35), 1 + (y * 35), 32, 32, w, h) end
  self.tilemap = {}
  self.tilemap.main = t(1, 4)
  self.tilemap.n = t(1, 3)
  self.tilemap.s = t(1, 5)
  self.tilemap.e = t(2, 4)
  self.tilemap.w = t(0, 4)
  self.tilemap.nw = t(0, 3)
  self.tilemap.ne = t(2, 3)
  self.tilemap.sw = t(0, 5)
  self.tilemap.se = t(2, 5)
  self.tilemap.inw = t(3, 3)
  self.tilemap.ine = t(4, 3)
  self.tilemap.isw = t(3, 4)
  self.tilemap.ise = t(4, 4)
end

function House:destroy()
  ovw.view:unregister(self)
end

function House:draw()
  local x1, x2 = self:snap(ovw.view.x, ovw.view.x + ovw.view.w)
  x1, x2 = x1 / self.cellSize - 1, x2 / self.cellSize + 1
  local y1, y2 = self:snap(ovw.view.y, ovw.view.y + ovw.view.h)
  y1, y2 = y1 / self.cellSize - 1, y2 / self.cellSize + 1
  for x = x1, x2 do
    for y = y1, y2 do
      if self.drawTiles and self.tiles[x] and self.tiles[x][y] then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.tileImage, self.tilemap[self.tiles[x][y]], x * self.cellSize, y * self.cellSize)
      end
    end
  end
end

function House:snap(x, ...)
  if not x then return end
  return math.floor(x / self.cellSize) * self.cellSize, self:snap(...)
end

function House:cell(x, ...)
  if not x then return end
  return x * self.cellSize, self:cell(...)
end

function House:generate()
  local opposite = {
    north = 'south',
    south = 'north',
    east = 'west',
    west = 'east'
  }

  local offset = {
    north = {0, -self.roomSpacing},
    south = {0, self.roomSpacing},
    east = {self.roomSpacing, 0},
    west = {-self.roomSpacing, 0}
  }
  
  -- Create initial room
  self:addRoom(RoomRectangle())

  -- Loop until 100 rooms are created
  repeat

    -- Pick a source room, create a destination room
    local oldRoom = randomFrom(self.rooms)
    local newRoom = randomFrom(self.roomTypes)()

    -- Pick a wall from the old room to add the newRoom to
    local oldWall = oldRoom:randomWall()
    local newWall = newRoom:randomWall(opposite[oldWall.direction])

    -- Position the new room
    newRoom:move(oldRoom.x + oldWall.x - newWall.x, oldRoom.y + oldWall.y - newWall.y)
    newRoom:move(unpack(offset[oldWall.direction]))

    -- If it doesn't overlap with another room, add it.
    if self:collisionTest(newRoom) then
      self:addRoom(newRoom)
      self:addDoor(oldRoom.x + oldWall.x, oldRoom.y + oldWall.y, newRoom.x + newWall.x, newRoom.y + newWall.y)
    end

  until #self.rooms > 100

  self:computeTiles()
end

function House:addRoom(room)
  for x = room.x, room.x + room.width do
    for y = room.y, room.y + room.height do
      self.grid[x] = self.grid[x] or {}
      self.grid[x][y] = 1
    end
  end

  for _, dir in pairs({'north', 'south', 'east', 'west'}) do
    for _, wall in pairs(room.walls[dir]) do
      local x, y = room.x + wall.x, room.y + wall.y
      self.grid[x] = self.grid[x] or {}
      self.grid[x][y] = 1
    end
  end

  table.insert(self.rooms, room)
end

function House:addDoor(x1, y1, x2, y2)
  local dx = math.sign(x2 - x1)
  local dy = math.sign(y2 - y1)

  if dx == 0 then
    for y = y1, y2, dy do
      for x = x1 - 2, x1 + 2 do
        self.grid[x] = self.grid[x] or {}
        self.grid[x][y] = 1
      end
    end
  end

  if dy == 0 then
    for x = x1, x2, dx do
      for y = y1 - 2, y1 + 2 do
        self.grid[x] = self.grid[x] or {}
        self.grid[x][y] = 1
      end
    end
  end
end

function House:collisionTest(room)
  local padding = self.roomSpacing - 1
  for x = room.x - padding, room.x + room.width + padding do
    for y = room.y - padding, room.y + room.height + padding do
      if self.grid[x] and self.grid[x][y] == 1 then return false end
    end
  end

  return true
end

function House:computeTiles()
  local function get(x, y)
    return self.grid[x] and self.grid[x][y] == 1
  end

  self.tiles = {}
  for x in pairs(self.grid) do
    for y in pairs(self.grid[x]) do
      if self.grid[x][y] and self.grid[x][y] == 1 then
        self.tiles[x] = self.tiles[x] or {}
        local n, s, e, w = get(x, y - 1), get(x, y + 1), get(x + 1, y), get(x - 1, y)
        local nw, ne = get(x - 1, y - 1), get(x + 1, y - 1)
        local sw, se = get(x - 1, y + 1), get(x + 1, y + 1)
        if w and e and not n then
          self.tiles[x][y] = 'n'
        elseif w and e and not s then
          self.tiles[x][y] = 's'
        elseif n and s and not e then
          self.tiles[x][y] = 'e'
        elseif n and s and not w then
          self.tiles[x][y] = 'w'
        elseif e and s and not w and not n then
          self.tiles[x][y] = 'nw'
        elseif w and s and not e and not n then
          self.tiles[x][y] = 'ne'
        elseif e and n and not w and not s then
          self.tiles[x][y] = 'sw'
        elseif w and n and not e and not s then
          self.tiles[x][y] = 'se'
        elseif w and n and not nw then
          self.tiles[x][y] = 'inw'
        elseif n and e and not ne then
          self.tiles[x][y] = 'ine'
        elseif s and w and not sw then
          self.tiles[x][y] = 'isw'
        elseif s and e and not se then
          self.tiles[x][y] = 'ise'
        elseif get(x, y) then
          self.tiles[x][y] = 'main'
        end
      end
    end
  end
end
