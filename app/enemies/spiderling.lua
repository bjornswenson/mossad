Spiderling = extend(Enemy)

Spiderling.collision = setmetatable({}, {__index = Enemy.collision})
Spiderling.collision.shape = 'circle'
Spiderling.collision.with = {
	wall = function(self, other, dx, dy)
		self.targetAngle = self.targetAngle + 180 + (love.math.random() * 90 - 45)
		self.skitterTargetX = ovw.player.x + math.dx(100, self.targetAngle)
		self.skitterTargetY = ovw.player.y + math.dy(100, self.targetAngle)
		self:setPosition(self.x + dx, self.y + dy)
	end,
	player = function(self, player, dx, dy)
		if self.state == 'bite' then
			player:hurt(self.damage)
			self:startSkitter()
		end
		return Enemy.collision.with.player(self, player, dx, dy)
	end,

	room = function(self, other, dx, dy)
		if self.room then
			if self.room ~= other then
			self.room:removeObject(self)
			other:addObject(self)
			end
		else
			other:addObject(self)
		end
	end
}
Spiderling.radius = 10

Spiderling.name = {}
Spiderling.name.singular = 'Spiderling'
Spiderling.name.pluralized = 'Spiderlings'

Spiderling.makeFootprints = false

-- States:
--   lurk - scanning for the player
--   skitter - roaming, waiting to attack
--   bite - charging at the player, dealing damage
--   fatigue - tired

function Spiderling:init(...)
	Enemy.init(self, ...)

	self.state = 'lurk'
	self.skitterTargetX = self.x
	self.skitterTargetY = self.y

	self.sight = 300

	self.target = nil

	self.biteSpeed = 400
	self.skitterSpeed = 225

	self.damage = 1
	self.exp = math.ceil(love.math.random() * 1.5)
	self.dropChance = .1

	self.scanTimer = 1
	self.skitterTimer = 0
	self.biteTimer = 0

	self.health = 5 * House.getDifficulty(true)
	self.maxHealth = self.health
	self.targetAngle = love.math.random() * 2 * math.pi
end

function Spiderling:update()
	Enemy.update(self)
	self.prevX = self.x
	self.prevY = self.y

	self[self.state](self)

	self:setPosition(self.x, self.y)
	self.angle = self.targetAngle--math.anglerp(self.angle, self.targetAngle, math.clamp(6 * tickRate, 0, 1))
end

function Spiderling:draw()
	local x, y = math.lerp(self.prevX, self.x, tickDelta / tickRate), math.lerp(self.prevY, self.y, tickDelta / tickRate)
	local tx, ty = ovw.house:cell(self.x, self.y)
	local v = ovw.house.tiles[tx] and ovw.house.tiles[tx][ty] and ovw.house.tiles[tx][ty]:brightness() or 1
	if self.state == 'bite' then
		love.graphics.setColor(255, 0, 0, v)
	elseif self.state ~= 'lurk' then
		love.graphics.setColor(255, 255, 0, v)
	else
		love.graphics.setColor(255, 255, 255, v)
	end
	local p23 = math.pi * 2 / 3
	local x1, y1 = self.x + math.dx(self.radius, self.angle), self.y + math.dy(self.radius, self.angle)
	local x2, y2 = self.x + math.dx(self.radius, self.angle - p23), self.y + math.dy(self.radius, self.angle - p23)
	local x3, y3 = self.x + math.dx(self.radius, self.angle + p23), self.y + math.dy(self.radius, self.angle + p23)
	love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3)

	if v > 25.5 then
		Enemy.drawHealth(self)
	end
end

function Spiderling:scan()
	self.target = nil
	local dis, dir = math.vector(self.x, self.y, ovw.player.x, ovw.player.y)

	self.scanTimer = .8

	if dis < self.sight then
		self.target = ovw.player
		self:startSkitter()
	end

	if not self.target then
		self.state = 'lurk'
	end
end

function Spiderling:startSkitter()
	if self.state ~= 'skitter' then
		self.skitterTimer = 1 + love.math.random() * 1
		self.scanTimer = 2
		self.state = 'skitter'
	end
	self.targetAngle = self.targetAngle + 180 + (love.math.random() * 60 - 30)
	self.skitterTargetX = ovw.player.x + math.dx(100, self.targetAngle)
	self.skitterTargetY = ovw.player.y + math.dy(100, self.targetAngle)
	local scuttle = ovw.sound:play('spider_scuttle.wav')
	scuttle:setVolume(ovw.sound.volumes.ambience)
end

----------------
-- States
----------------
function Spiderling:lurk()
	self.scanTimer = self.scanTimer - tickRate

	if self.scanTimer <= 0 then
		self:scan()
	end
end

function Spiderling:skitter()
	self.scanTimer = self.scanTimer - tickRate

	if self.scanTimer <= 0 then
		self:scan()
	end


	local tx, ty = self.skitterTargetX, self.skitterTargetY
	local dis, dir = math.vector(self.x, self.y, tx, ty)
	local speed = math.clamp(self.skitterSpeed * tickRate * (dis / 20), dis * tickRate, self.skitterSpeed * tickRate)
	self.x = self.x + math.dx(speed, dir)
	self.y = self.y + math.dy(speed, dir)

	self.skitterTimer = self.skitterTimer - tickRate
	local d = math.distance(self.x, self.y, self.skitterTargetX, self.skitterTargetY)
	if self.skitterTimer <= 0 or d < 5 then
		if not ovw.collision:lineTest(self.x, self.y, ovw.player.x, ovw.player.y, 'wall') and love.math.random() < .7 then
			self.targetAngle = math.direction(self.x, self.y, ovw.player.x, ovw.player.y)
			self.state = 'bite'
			self.biteTimer = .8
			local scuttle = ovw.sound:play('spider_scuttle.wav')
			scuttle:setVolume(ovw.sound.volumes.ambience)
		else
			self.state = 'fatigue'
		end
	end
end

function Spiderling:bite()
	local dis, dir = math.vector(self.x, self.y, ovw.player.x, ovw.player.y)
	local speed = self.biteSpeed * tickRate
	self.x = self.x + math.dx(speed, self.angle)
	self.y = self.y + math.dy(speed, self.angle)
	self.targetAngle = dir

	self.biteTimer = timer.rot(self.biteTimer, function()
		self:startSkitter()
	end)
end

function Spiderling:fatigue()
  self.scanTimer = .3
  self.state = 'lurk'
end