NPC = class()

NPC.tag = 'npc'
NPC.collision = {
	with = {}
}

NPC.npcType = 'NPC'

function NPC:init(data)
	self.x, self.y = 0, 0
	self.state = 'Not'
	self.timers = {}
	self.timers.fadeIn = 1
	self.timers.fadeOut = 0
	for k, v in pairs(data) do self[k] = v end
	assert(self.room)
	self.id = 0
	self.name = 'Unnamed Non-Player Character'
	self.noteTag = ''
	self.room:addObject(self)
	self.angle = 0
	self.depth = DrawDepths.movers
	ovw.collision:register(self)
	ovw.view:register(self)
end

function NPC:destroy()
	self.room:removeObject(self)
	ovw.collision:unregister(self)
	ovw.view:unregister(self)
end

function NPC:remove()
	ovw.npcs:remove(self)
end

function NPC:update()
	if math.distance(self.x, self.y, ovw.player.x, ovw.player.y + 12) < 40 then
		self.state = 'Hot'
		if ovw.player.npc ~= self then ovw.player.npc = self end
	else
		self.state = 'Not'
		if ovw.player.npc == self then ovw.player.npc = nil end
	end
	if love.keyboard.isDown('e') then
		self.timers.fadeIn = timer.rot(self.timers.fadeIn)
		self.timers.fadeOut = 1 - self.timers.fadeIn
	else
		self.timers.fadeOut = timer.rot(self.timers.fadeOut)
		self.timers.fadeIn = 1 - self.timers.fadeOut
	end
end

function NPC:draw()
	local tx, ty = ovw.house:cell(self.x, self.y)
	local v = (ovw.house.tiles[tx] and ovw.house.tiles[tx][ty]) and ovw.house.tiles[tx][ty]:brightness() or 1
	if self.state == 'Hot' then
		love.graphics.setColor(255, 255, 0, 255)
	else
		love.graphics.setColor(255, 255, 255, v)
	end
	self.shape:draw('line')
end

NPC.activate = f.empty

function NPC:setPosition(x, y)
	self.x, self.y = x, y
	self.shape:moveTo(x, y)
end