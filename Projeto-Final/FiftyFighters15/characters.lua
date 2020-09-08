--======================= The Characters Table ===============================--

Characters = {

    ['Athena'] = {
        ['armor'] = 90,
        ['damage'] = 15,
        ['range'] = 55,
        ['passive'] = function(dt, self)
            if self.state == 'jumping' then
                self:detectDamage()

            elseif self.state == 'winning' then
                self.y = self.map.floor
            end
        end,
        ['special'] = function(dt, self)
            self.x = math.floor(self.x - 2 * self.speed * self.direction * dt)
            self:detectDamage()
            if self.animation.currentFrame == #self.animation.frames and self.animation.timer >= self.animation.interval then
                self.state = 'idle'

            end
        end

    },
    ['Benimaru'] = {
        ['armor'] = 30,
        ['damage'] = 20,
        ['range'] = 30,
        ['passive'] = function(dt, self)
            if self.health < 30 then
                self.damage = 40
            end
        end
    }





}
