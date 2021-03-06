local io = io
local math = math
local naughty = require("naughty")
local beautiful = require("beautiful")
local tonumber = tonumber
local tostring = tostring
local print = print
local pairs = pairs
local battery = {}

local limits = {{25, 5},
          {12, 3},
          { 7, 1},
            {0}}

function battery.get_bat_state (adapter)
    local cur = nil 
    local cap = nil
    local sta = nil
    local dir = nil
    local battery = ""
    if io.open("/sys/class/power_supply/"..adapter) then
        local fcur = io.open("/sys/class/power_supply/"..adapter.."/energy_now") or io.open("/sys/class/power_supply/"..adapter.."/charge_now")  
        local fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full") or io.open("/sys/class/power_supply/"..adapter.."/charge_full") 
        local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")

	cur = fcur:read();
        cap = fcap:read();
        sta = fsta:read();

        fcur:close()
        fcap:close()
        fsta:close()
        battery = math.floor(cur * 100 / cap)
        if sta:match("Charging") then
            dir = 1
        elseif sta:match("Discharging") then
            dir = -1
        else
           dir = 0
        end
    end
    
    return battery, dir
end

function battery.getnextlim (num)
    for ind, pair in pairs(limits) do
        lim = pair[1]; step = pair[2]; nextlim = limits[ind+1][1] or 0
        if num > nextlim then
            repeat
                lim = lim - step
            until num > lim
            if lim < nextlim then
                lim = nextlim
            end
            return lim
        end
    end
end


function battery.batclosure (adapter)
    local nextlim = limits[1][1]
    return function ()
        local prefix = "⚡"
        local lim, dir = battery.get_bat_state(adapter)
	local battery_display = ""
        if dir == -1 then
            dirsign = "↓"
            if lim <= nextlim then
                naughty.notify({title = "⚡ Beware! ⚡",
                           text = "Battery charge is low ( ⚡ "..lim.."%)!",
                            timeout = 7,
                            position = "bottom_right",
                            fg = beautiful.fg_focus,
                            bg = beautiful.bg_focus
                            })
                nextlim = battery.getnextlim(lim)
            end
        elseif dir == 1 then
            dirsign = "↑"
            nextlim = limits[1][1]
        elseif dir == 0 then
            dirsign = ""
        else
            prefix = ""
            dirsign = ""
        end
        if dir then 
            lim = lim.."%" 
	    battery_display = " "..prefix..dirsign..lim..dirsign.." "
        end
        return battery_display
    end
end

return battery
