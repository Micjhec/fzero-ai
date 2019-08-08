-- Client class for connecting to learning server

local Client = {}

Client.conn = nil

-- Conncects to server at specified host and port
function Client.connect(host, port)
    local sock = require('socket')
    print("Connecting to " .. host .. ':' .. port .. '...')
    Client.conn, err = socket.connect(host, port)
    if Client.conn == nil then
        print('Error connecting to server at ' .. host .. ':' .. port)
        error(err)
    end

    Client.conn:settimeout(-1)
    Client.conn:setoption('tcp-nodelay', true)
end

function Client.close()
    if Client.conn ~= nil then
        Client.conn:send("close\n")
        Client.conn:close()
    end
    Client.conn = nil
end

-- Receives a line of data from the server
-- Returns string
function Client.receiveLine()
    local data = nil
    local err = nil
    data, err = Client.conn:receive('*l') -- read line, LF (ASCII 10) terminated. LF excluded
    -- data, err = Client.conn:receive('*a') -- read until connection closed
    -- data, err = Client.conn:receive(1) -- read number of bytes

    -- TODO: throw error and handle outside
    if err ~= nil then
        error(err)
    else
        return data
    end
end

-- Sends a line of data to the server
function Client.sendLine(line)
    local line = line .. '\n'
    local sent, err, lastindex = Client.conn:send(line)

    if err ~= nil then
        error(err)
    end
end

function Client.sendList(list)
    line = ''
    for i=1,#list do
        line = line .. list[i] .. ' '
    end
    Client.sendLine(line)
end

-- Recieve button presses from server
function Client.receiveButtons(buttonNames)
    local data = Client.receiveLine()
    if data == nil then 
        error('error: button data nil') 
    end
    if #data ~= #buttonNames then 
        Client.close()
        error('Error: unexpected buttons length ' .. #data .. ' ' .. data)
        return
    end

    local buttons = {}
    for i,v in ipairs(buttonNames) do
        buttons[v] = (data:sub(i,i) == '1' and true or false)
    end

    return buttons
end

return Client
