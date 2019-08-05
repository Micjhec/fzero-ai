-- Main script for playing the game
-- run this in bizhawk

BUTTON_NAMES = {
    'Right',
    'B',
    'Y',
}

-- This line is temporary for ease of reloading and testing in bizhawk
-- should probably be removed and/or modules refactored for better style/functionality
package.loaded.client = nil

client = require('client')

local ENDSTAT
local ENDSTATAddr=0xC3

status, err = pcall(client.connect, '127.0.0.1', 2222)

while true do
    ENDSTAT=memory.readbyte(ENDSTATAddr)
    if ENDSTAT == 64 then
        client.close()
		--savestate.loadslot(1)
	else
		if status then
            local buttons = nil
            buttons = client.receiveButtons(BUTTON_NAMES)
            joypad.set(buttons,1)
        end
	end
    
    emu.frameadvance()
end