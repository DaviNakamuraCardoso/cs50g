--============================ Player Class ==================================--

Player = Class{}

require 'characters'

function Player:init(map, name, side, range)
    self.map = map
    self.name = name

    -- Combat status
    self.armor = Characters[self.name]['armor']
    self.health = 100
    self.range = Characters[self.name]['range']
    self.damage = Characters[self.name]['damage']

    -- Passive and Special Ability
    self.passive = Characters[self.name]['passive']
    self.special = Characters[self.name]['special']



    -- 1 or -1, 1 representing the right side and -1 the left side
    self.side = side
    -- Position and dimensions
    self.x = self.map.camX + VIRTUAL_WIDTH / 2 + (VIRTUAL_WIDTH / 2 * self.side)
    self.y = self.map.floor
    self.width = 100
    self.height = 160

    self.dx = 0
    self.dy = 0

    -- Offsets for flipping
    self.xOffset = self.width / 2
    self.yOffset = self.height / 2


    -- Enemy
    self.enemy = nil
    --//_________________________ Animations ___________________________\\--
    self.animations = {

        ['idle'] = Animation(
            love.graphics.newImage('graphics/' .. self.name ..  '/idle.png'),
            generateQuads('graphics/' .. self.name .. '/idle.png', self.width, self.height),
            0.3
        ),
        ['walking'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/walking.png'),
            generateQuads('graphics/' .. self.name .. '/walking.png', self.width, self.height),
            0.1
        ),
        ['attacking'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/attacking.png'),
            generateQuads('graphics/' .. self.name .. '/attacking.png', self.width, self.height),
            0.05
        ),
        ['jumping'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/jumping.png'),
            generateQuads('graphics/' .. self.name .. '/jumping.png', self.width, self.height),
            0.4
        ),
        ['dying'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/dying.png'),
            generateQuads('graphics/' .. self.name .. '/dying.png', self.width + 50, self.height),
            0.4
        ),
        ['waiting'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/waiting.png'),
            generateQuads('graphics/' .. self.name .. '/waiting.png', self.width, self.height),
            0.2
        ),
        ['hurt'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/hurt.png'),
            generateQuads('graphics/' .. self.name .. '/hurt.png', self.width, self.height),
            0.1
        ),
        ['winning']  = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/winning.png'),
            generateQuads('graphics/' .. self.name .. '/winning.png', self.width, self.height),
            0.2
        ),
        ['special'] = Animation(
            love.graphics.newImage('graphics/' .. self.name .. '/special.png'),
            generateQuads('graphics/' .. self.name .. '/special.png', self.width + 50, self.height),
            0.1
        )

    }

    self.animation = self.animations['idle']
    self.currentFrame = self.animation:getCurrentFrame()

    --//_________________________ Behaviors ____________________________\\--
    self.speed = 200
    self.jumpSpeed = -600
    self.direction = self.side
    local keyRelations = {
        [-1] = {
            ['forward'] = 'd',
            ['backward'] = 'a',
            ['jump'] = 'space',
            ['attack'] = 'f',
            ['special'] = 'g'

        },
        [1] = {
            ['forward'] = 'right',
            ['backward'] = 'left',
            ['jump'] = 'up',
            ['attack'] = '/'
        }
    }
    self.behaviors = {
        ['idle'] = function(dt)
            if love.keyboard.isDown(keyRelations[self.side]['backward']) then
                self.x = math.max(0, math.floor(self.x - self.speed * dt))
                self.state = 'walking'
                self.direction = 1

            elseif love.keyboard.isDown(keyRelations[self.side]['forward']) then
                self.x = math.min(self.map.mapWidth - self.width, math.floor(self.x + self.speed * dt))
                self.state = 'walking'
                self.direction = -1

            elseif love.keyboard.wasPressed[keyRelations[self.side]['attack']] then
                self.state = 'attacking'

            elseif love.keyboard.wasPressed[keyRelations[self.side]['jump']] then
                self.dy = self.jumpSpeed
                self.state = 'jumping'


            elseif love.keyboard.wasPressed[keyRelations[self.side]['special']] then
                self.state = 'special'

            end


        end,
        ['walking'] = function(dt)
            if love.keyboard.isDown(keyRelations[self.side]['backward']) then
                self.x = math.max(0, math.floor(self.x - self.speed * dt))
                self.direction = 1
            elseif love.keyboard.isDown(keyRelations[self.side]['forward']) then
                self.x = math.min(self.map.mapWidth - self.width, math.floor(self.x + self.speed * dt))
                self.direction = -1

            elseif love.keyboard.wasPressed['r'] then
                self.state = 'attacking'
            else
                self.state = 'idle'
            end
        end,
        ['attacking'] = function(dt)
            self:detectDamage()
            if self.animation.currentFrame == #self.animation.frames and self.animation.timer >= self.animation.interval then
                self.animation.currentFrame = 0
                self.state = 'idle'

            end
            if love.keyboard.isDown(keyRelations[self.side]['backward']) then
                self.x = math.max(0, math.floor(self.x - self.speed * dt))
                self.state = 'walking'
                self.direction = 1

            elseif love.keyboard.isDown(keyRelations[self.side]['forward']) then
                self.x = math.min(self.map.mapWidth - self.width, math.floor(self.x + self.speed * dt))
                self.state = 'walking'
                self.direction = -1
            end
        end,
        ['jumping'] = function(dt)
            self.y = math.floor(self.y + self.dy * dt)
            if self.y >= self.map.floor then
                self.y = self.map.floor
                self.dy = 0
                self.state = 'idle'
            else
                self.dy = self.dy + self.map.gravity
            end

        end,
        ['dying'] = function(dt)
            if self.animation.currentFrame == (#self.animation.frames) and self.animation.timer >= self.animation.interval then
                self.state = 'waiting'

            else
                self.direction = - self.enemy.direction
                self.x = math.min(self.map.mapWidth - self.width, math.max(self.map.camX, math.floor(self.x + self.speed * dt / 2 * self.direction)))
            end
        end,
        ['waiting'] = function(dt)

        end,

        ['hurt'] = function(dt)
            if self.animation.currentFrame == #self.animation.frames and self.animation.timer >= self.animation.interval then
                if self.health <= 0 then
                    self.state = 'dying'
                    self.enemy.state = 'winning'
                elseif self.y < self.map.floor then
                    self.state = 'jumping'
                else
                    self.state = 'idle'
                end
            end
        end,
        ['winning'] = function(dt)

        end,
        ['special'] = function(dt)
            self.special(dt, self)
        end


    }
    self.state = 'idle'

end



function Player:update(dt)
    self.animation = self.animations[self.state]
    self.currentFrame = self.animation:getCurrentFrame()
    self.animation:update(dt)
    self.behaviors[self.state](dt)
    self.passive(dt, self)
    self.x = math.max(self.map.camX - 10, math.min(self.map.camX + VIRTUAL_WIDTH - 90, self.x))
end



function Player:render()
    love.graphics.draw(self.animation.texture, self.currentFrame, math.floor(self.x + self.xOffset), math.floor(self.y + self.yOffset), 0, self.direction, 1, self.xOffset, self.yOffset)

end


function Player:enemyAt(x, y)
    if self.enemy.y <= y and y <= self.enemy.y + self.enemy.height then
        if self.enemy.x <= x and x <= self.enemy.x + self.enemy.width then
            return true
        elseif self.enemy.x >= x and x >= self.enemy.x + self.enemy.width then
            return true
        else
            return false
        end
    else
        return false
    end
end


--//__________________________ Damage detection ____________________________\\--
function Player:detectDamage()
    if self.animation.timer >= self.animation.interval then

        -- checks for enemies in a circle arround the character
        for i=0, 360 do
            local x = self.x + self.width / 2 + (math.cos(math.rad(i)) * self.range)
            local y = self.y + self.height / 2 + (math.sin(math.rad(i)) * self.range)
            if self:enemyAt(x, y) and self.enemy.state ~= 'hurt' then
                self.enemy.state = 'hurt'
                self.enemy.health = self.enemy.health - (self.damage - self.enemy.armor / 10)
                self.enemy.x = math.min(512, math.max(0, math.floor(self.enemy.x - self.direction *   self.range / 2)))
            end

        end
    end
end
--\\________________________________________________________________________//--