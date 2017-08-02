-- frame function wrapper
function ffunc(frame, think, callback)
    return function()
        self.frame = frame
        self.nextthink = time + 0.1
        self.think = think
        if callback then
            callback()
        end
    end
end

require "defs"
require "subs"
require "combat"
require "items"
require "weapons"
require "world"
require "client"
require "spectate"
require "player"
require "doors"
require "buttons"
require "triggers"
require "plats"
require "misc"
require "server"

-- client.lua
function WaterMove() end
function CheckPowerups() end
