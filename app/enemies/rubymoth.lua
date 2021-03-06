RubyMoth = extend(Enemy)

RubyMoth.collision = setmetatable({}, {__index = Enemy.collision})
--RubyMoth.collision.with.enemy = nil

RubyMoth.collision.shape = 'circle'
RubyMoth.radius = 10

RubyMoth.image = love.graphics.newImage('media/graphics/enemies/rubyMoth.png')
RubyMoth.image:setFilter('nearest')
RubyMoth.anim = newAnimation(RubyMoth.image, 40, 40, 1)

RubyMoth.name = {}
RubyMoth.name.singular = 'Ruby Moth'
RubyMoth.name.pluralized = 'Ruby Moths'

RubyMoth.deathCry = 'sad_moth_modified.wav'

RubyMoth.makeFootprints = false

function RubyMoth:init(...)
	Enemy.init(self, ...)

	self.anim = table.copy(RubyMoth.anim)

	self.state = 'roam'

	self.sight = 150
	self.scanTimer = 0

	self.walkSpeed = 50
	self.followSpeed = 0 --required for most follow() functions!
	self.circleSpeed = love.math.random() * 30 + 20 --see above comment.
	self.speed = self.walkSpeed
	if love.math.random() < .5 then self.circleDir = -1 else self.circleDir = 1 end

	self.damage = 0
	self.exp = 0
	self.dropChance = .35

	self.light = {
		minDis = 0,
		maxDis = 300,
		shape = 'circle',
		intensity = 0.7,
		falloff = .95,
		posterization = 1,
		flicker = .9,
		color = {255, 110, 110, 3}
	}

	self.health = 1
	self.maxHealth = self.health
	self.targetAngle = love.math.random() * 2 * math.pi
	self.followTarget = nil
end

function RubyMoth:destroy() --for all followers!
	Enemy.destroy(self)
	ovw.player.followers[self] = nil
end

function RubyMoth:update()
	Enemy.update(self)
	self.prevX = self.x
	self.prevY = self.y

	self[self.state](self)

	self.light.x, self.light.y = self.x, self.y
	ovw.house:applyLight(self.light, 'ambient')

	self:setPosition(self.x, self.y)
	self.speed = math.lerp(self.speed, self.followSpeed, math.clamp(tickRate, 0, 1))
	self.angle = math.anglerp(self.angle, self.targetAngle, math.clamp(6 * tickRate, 0, 1))

	self.anim:update(tickRate)
end

function RubyMoth:draw()
	local x, y = math.lerp(self.prevX, self.x, tickDelta / tickRate), math.lerp(self.prevY, self.y, tickDelta / tickRate)
	local tx, ty = ovw.house:cell(self.x, self.y)
	local v = ovw.house.tiles[tx] and ovw.house.tiles[tx][ty] and ovw.house.tiles[tx][ty]:brightness() or 1
	local brightness = 150
	if self.state == 'follow' then
		love.graphics.setColor(brightness, brightness, brightness - 20, v)
	else
		love.graphics.setColor(brightness, brightness, brightness, v)
	end
	--self.shape:draw('line')
	self.anim:draw(x - self.anim:getWidth() / 2, y - self.anim:getHeight() / 2)
end

function RubyMoth:scan()
	local dis, dir = math.vector(self.x, self.y, ovw.player.x, ovw.player.y)

	self.scanTimer = .3

	if dis < self.sight then
		local blocked = ovw.collision:lineTest(self.x, self.y, ovw.player.x, ovw.player.y, 'wall')
    	if not blocked then
			self.followTarget = ovw.player
			self.state = 'follow'
			ovw.player.followers[self] = self
			local flap = ovw.sound:play('moth_flap.wav')
			flap:setVolume(ovw.sound.volumes.fx)
		end
	end

	if not self.followTarget then
    	self.targetAngle = self.targetAngle + (love.math.random() * 360 - 180)
		self.state = 'roam'
	end
end

----------------
-- States
----------------
function RubyMoth:roam()
	self.scanTimer = self.scanTimer - tickRate

	if self.scanTimer <= 0 then
		self:scan()
	end

	self.x = self.x + math.dx(self.walkSpeed * tickRate, self.angle)
	self.y = self.y + math.dy(self.walkSpeed * tickRate, self.angle)
end

function RubyMoth:follow() --required state for all followers!
	local dis = 0
	dis, self.targetAngle = math.vector(self.x, self.y, self.followTarget.x, self.followTarget.y)
	self.followSpeed = dis - 25 + self.circleSpeed
	if dis > 75 then
		self.x = self.x + math.dx(self.followSpeed * tickRate, self.angle)
		self.y = self.y + math.dy(self.followSpeed * tickRate, self.angle)
	else
		self.followSpeed = self.circleSpeed
		self.angle = self.angle + self.circleDir * love.math.random() * math.pi / 6
		self.x = self.x + math.dx(self.followSpeed * tickRate, self.angle)
		self.y = self.y + math.dy(self.followSpeed * tickRate, self.angle)
	end
end