

--Variables used thoughout the functions
Vehicle_X_Position = nil
Vehicle_Y_Position = nil
Vehicle_Direction_Raw = nil
Vehicle_Direction_Angles = nil
Vehicle_Speed = nil
Screen_Size = nil
Half_Width = nil
AI_Inputs = {}

Global_Max_Angle = 49142

--SMKScreen, using this to set how much the AI will see as inputs
Global_Screen_Width = 15
Global_Screen_Heigth = 15
Global_Skew = 1.05
Global_Tilt_Shift = 0.3
Global_Input_Resolution = 24
Global_Tile_Size = 32

--Stack overflow 
function toBits(num, bits)
    -- returns a table of bits
    local t={} -- will contain the bits
    for bitIndex = bits,1,-1 do
        rest=math.fmod(num,2)
        t[bitIndex]=rest
        num=(num-rest)/2
    end
    
	return t
end

--Not currently used. 
--function Get_Table_Index(Local_Table, How_Many_Bits, Steps, Start_Index, Stop_Index, Off_Set)
	--local index
	--for i = How_Many_Bits, Start_Index, Stop_Index, Steps do
		--i = i + (Local_Table[i] * (math.pow(2, (How_Many_Bits - i + Off_Set))))
	--end
	
	--return index
--end

function Get_Vehicle_Details()
    
	--console.log("Calculated Position")
    
	Vehicle_X_Position = mainmemory.read_u16_le(0x000B70)
	Vehicle_Y_Position = mainmemory.read_u16_le(0x000B90)
	Vehicle_Direction_Raw = mainmemory.read_u16_le(0x000010)
	Vehicle_Speed = mainmemory.read_u16_le(0x000B20)
	
	--console.log("X Position =")
	--console.log(Vehicle_X_Position)
	
	--console.log("Y Position =")
	--console.log(Vehicle_Y_Position)
	
	--console.log("Direction Raw =")
	--console.log(Vehicle_Direction_Raw)
	
	--console.log("Vehicle_Speed =")
	--console.log(Vehicle_Speed)
end

-- Keep this for map display
function Get_Tile_Value(Current_Tile)
	if Current_Tile >= 0x00 and Current_Tile <= 0x68 then -- Wall 
		return -1
	elseif Current_Tile >= 0x69 and Current_Tile <= 0x81 then --Empty Space
	    return -1
	elseif Current_Tile >= 0x82 and Current_Tile <= 0x9C then --Road
		return 1
	elseif Current_Tile	>= 0x9D and Current_Tile <= 0x9F then -- Powerup
		return 1.5
	elseif Current_Tile >= 0xA0 and Current_Tile <= 0xA0 then --Road	
		return 1
	elseif Current_Tile >= 0xA1 and Current_Tile <= 0xA4 then -- Powerup
		return 1.5
	elseif Current_Tile >= 0xA5 and Current_Tile <= 0xA5 then -- Empty Space
		return -1
	elseif Current_Tile >= 0xA6 and Current_Tile <= 0xA6 then -- ????? its a square
		return 1
	elseif Current_Tile >= 0xA7 and Current_Tile >= 0xAF then -- Dirt
		return .5
	elseif Current_Tile >= 0xB0 and Current_Tile >= 0xB8 then -- Sparkly Road
		return 1
	elseif Current_Tile >= 0xB9 and Current_Tile >= 0xBF then --?????
		return -1
	elseif Current_Tile >= 0xC0 and Current_Tile >= 0xC1 then -- road???
	    return 1
	elseif Current_Tile >= 0xC2 and Current_Tile >= 0xFF then -- **NOT MAPPED**
		return 0
	else 
		return 0
	end
end

--SMKSCreen, 
function Update_Screen_variables()
	Half_Width = math.floor(Global_Screen_Width/2)
	Screen_Size = Global_Screen_Width*Global_Screen_Heigth
end

function Find_Tile_Value(X_Postion, Y_Position)
	--Tile data is broken into 3 tables. Then a tile pool
	--First Table is a set of 512 Panels
	--To locate a table you need to find the bits 9-12 of the Y Position
	--and bits 9-13 of the X Position
	--Ex. X = 255 Y= 256 , that is x = 00FF and x = 0100, that would be
	--x= 000[0 0000] 1111 1111 and y = 0000 [0001] 0000 0000
	--so Y would be 0001 and x woould be 0 0000
	--you then combine them to in the form YYYYXXXXX
	--this would make it 00010000
	--that is used as an offset to 0x014c00, the byte value from that memory 
	--is then used on table 2
	--Table 2 is index by the byte value * 32 + YYYY0
	--where Y are bits 5-8 of the Y Position
	--**CONTINUE EXPLANATION**
    local Max_Y_Number_Of_Bits = 16
	local Max_X_number_Of_Bits = 16
	local Table_1_XBits_Stop = ((Max_X_number_Of_Bits + 1) - 13)
	local Table_1_XBits_Start = ((Max_X_number_Of_Bits + 1) - 9)
	local Table_1_YBits_Stop = ((Max_Y_Number_Of_Bits + 1) - 12)
	local Table_1_YBits_Start = ((Max_Y_Number_Of_Bits + 1) - 9)
	local Table_1_Y_Offset = 5
	local Table_2_YBits_Stop = ((Max_Y_Number_Of_Bits + 1) - 8)
	local Table_2_YBits_Start = ((Max_Y_Number_Of_Bits + 1) - 5)
	local Tabel_2_Y_Offset = 1
	local Table_3_XBits_Stop = ((Max_X_number_Of_Bits + 1) - 8)
	local Table_3_XBits_Start = ((Max_X_number_Of_Bits + 1) - 5)
	local Tabel_3_X_Offset = 1

    --get YYYY YYYY YYYY YYYY
	local Y_Table = {}
	local Y_Table = toBits(Y_Position, Max_Y_Number_Of_Bits)
	
	--get XXXX XXXX XXXX XXXX
    local X_Table = {}
	local X_Table = toBits(X_Postion, Max_X_number_Of_Bits)
	
	-- console.log("Y table = ")
	-- console.log(Y_Table)
	
	-- console.log("X table = ")
	-- console.log(X_Table)
	
	--Get Offset for table 2
	local Table_1_Offset = 0
	for X_Table_1_Offset_Index = Table_1_XBits_Start, Table_1_XBits_Stop, -1 do	
		Table_1_Offset = Table_1_Offset + (X_Table[X_Table_1_Offset_Index] * (math.pow(2, (Table_1_XBits_Start - X_Table_1_Offset_Index))))
    end
	
	-- console.log("Table_1_Offset = ")
	-- console.log(Table_1_Offset)
	
	for Y_Table_1_Offset_Index = Table_1_YBits_Start, Table_1_YBits_Stop, -1 do	
		Table_1_Offset = Table_1_Offset + (Y_Table[Y_Table_1_Offset_Index] * (math.pow(2, (Table_1_YBits_Start - Y_Table_1_Offset_Index + Table_1_Y_Offset))))
    end
	
	-- console.log("Table_1_Offset = ")
	-- console.log(Table_1_Offset)
	
	local Byte_For_Table_2 = mainmemory.read_u8(0x014c00 + Table_1_Offset)
	
	-- console.log("Byte_For_Table_2 = ")
	-- console.log(Byte_For_Table_2)
	
	--Get Offset for table 3
	Table_2_Offset = 0
	for Y_Table_2_Offset_Index = Table_2_YBits_Start, Table_2_YBits_Stop, -1 do	
		Table_2_Offset = Table_2_Offset + (Y_Table[Y_Table_2_Offset_Index] * (math.pow(2, (Table_2_YBits_Start - Y_Table_2_Offset_Index + Tabel_2_Y_Offset))))
    end
	
	-- console.log("Table_2_Offset = ")
	-- console.log(Table_2_Offset)
	
	local Byte_For_Table_3 = mainmemory.read_u16_le(0x015000 + (Byte_For_Table_2 * 32) + Table_2_Offset) 
	
	-- console.log("Byte_For_Table_3 = ")
	-- console.log(Byte_For_Table_3)
	
	--Get Offset for the actual tile
	local Table_3_Offset = 0
	for X_Table_3_Offset_Index = Table_3_XBits_Start, Table_3_XBits_Stop, -1 do	
		Table_3_Offset = Table_3_Offset + (X_Table[X_Table_3_Offset_Index] * (math.pow(2, (Table_3_XBits_Start - X_Table_3_Offset_Index + Tabel_3_X_Offset))))
    end
	
	-- console.log("Table_3_Offset = ")
	-- console.log(Table_3_Offset)
	
	local Byte_For_Tile_Pool = mainmemory.read_u16_le(0x010000 + Byte_For_Table_3 + Table_3_Offset)
	
	-- console.log("Byte_For_Tile_Pool = ")
	-- console.log(Byte_For_Tile_Pool)
	
	local Tile = mainmemory.read_u8(0x010000 + Byte_For_Tile_Pool)
	
	-- console.log("Tile = ")
	-- console.log(Tile)
	
	return Tile
end


Update_Screen_variables()

function Get_Car_Dircection_In_Degrees()
	Vehicle_Direction_Angles = math.floor(((Vehicle_Direction_Raw / Global_Max_Angle) * 360))
	
	--console.log("Vehicle_Direction_Angles =")
	--console.log(Vehicle_Direction_Angles)
end

function Get_Tile(parallelDist, orthDist, facingVec)
	local dir = facingVec
	local orth = {-dir[2], dir[1]}
	local Return_Tile
	
	if Global_Tilt_Shift ~= 0 then
		parallelDist = parallelDist * parallelDist * Global_Tilt_Shift
	end
	
	orthDist = orthDist * (parallelDist * (Global_Skew - 1) + 1)
	
	local dx = parallelDist*dir[1]+orthDist*orth[1]
	local dy = parallelDist*dir[2]+orthDist*orth[2]
	
	local Current_X_Value = math.floor((Vehicle_X_Position+dx*Global_Input_Resolution))
	local Current_Y_Value = math.floor((Vehicle_Y_Position+dy*Global_Input_Resolution))

	if Current_X_Value >= 1 and Current_X_Value <= 8191 and Current_Y_Value >= 1 and Current_Y_Value <= 4095 then
		Return_Tile = Find_Tile_Value(Current_X_Value, Current_Y_Value)
		return Return_Tile
	else
		return -1
	end
end

function Get_Inputs_For_AI()
	--console.log("Starting Input Creation")
	
	AI_Inputs = {}
	
	local Current_Direction = {math.sin(math.rad(Vehicle_Direction_Angles)), -math.cos(math.rad(Vehicle_Direction_Angles))}
	
	--console.log("Get_Inputs_For_AI local variable Current_Direction =")
	--console.log(Current_Direction)
	
	local AI_Inputs_Index = 1
	local Tile_Color = 1
	
	for Current_Tile_Row = Global_Screen_Heigth, 1, -1 do
		for Current_Tile_Column = -Half_Width, Half_Width do
			AI_Inputs[#AI_Inputs+1] = Get_Tile(Current_Tile_Row, Current_Tile_Column, Current_Direction)
			
			--Draw As we go
			if Tile_Color ~= nil then
				--console.log("Trying to get tile color")	
			    --console.log("Tile is =")
				--console.log(AI_Inputs[AI_Inputs_Index])
				
				Tile_Color = Get_Tile_Value(AI_Inputs[AI_Inputs_Index])
				
				--console.log("Tile_Color is =")
				--console.log(Tile_Color)
				
				if Tile_Color ~= nil then 
					Tile_Color = math.floor((Tile_Color+2)/4*255)
				end
			end
			if Tile_Color ~= nil then
				Tile_Color = Tile_Color + Tile_Color*0x100 + Tile_Color*0x10000 + 0xFF*0x1000000
				--console.log("Got tile color")
			end
			
			gui.drawPixel(Current_Tile_Row+5, Current_Tile_Column+5, Tile_Color)
			AI_Inputs_Index = AI_Inputs_Index + 1
		end
	end
	
	--console.log("Stoping Input Creation")
	--console.log("AI_Inputs =")
	--console.log(AI_Inputs)
end


while true do

--Get Car positions
    Get_Vehicle_Details()

--Calculate angle of car
    Get_Car_Dircection_In_Degrees()
	
--GetInputs
    Get_Inputs_For_AI()

--Display Screen

	-- vehicleX = mainmemory.read_s16_le(0x000B70)
	-- vehicleY = mainmemory.read_s16_le(0x000B90)
	
	-- local test_tile = Find_Tile_Value(vehicleX, vehicleY)
	
	-- console.log("test_tile = ")
	-- console.log(test_tile)
	
	-- --get yyyy
    -- -- returns a table of bits
	-- ytable = {}
    -- ytable = toBits(vehicleY, 16)

	-- --get xxxxx
	-- xtable = {}
	-- xtable = toBits(vehicleX, 16)
	
	--get index
	-- table1Index = 0
	-- for tableIndex = xbits, 1, -1 do	
		-- table1Index = table1Index + (xtable[tableIndex] * (math.pow(2, (xbits - tableIndex))))
    -- end
	
	-- for tableIndex = ybits, 1, -1 do	
		-- table1Index = table1Index + (ytable[tableIndex] * (math.pow(2, (xbits - tableIndex + ybits))))
    -- end
	
	-- newYtable = toBits(mainmemory.read_s8(0x000B90), 8)
	-- table2Index = 0
	-- for tableIndex = 4, 1, -1 do	
		-- table2Index = table2Index + (newYtable[tableIndex] * (math.pow(2, (5 - tableIndex))))
    -- end
	
	
	-- byteForTable2 = mainmemory.read_u8(0x014c00 + table1Index)
	-- offsetForTable2 = mainmemory.read_u16_le(0x015000 + (byteForTable2 * 32) + table2Index) 
	
	-- newXtable = toBits(mainmemory.read_s8(0x000B70), 8)
	-- table3Index = 0
	-- for tableIndex = 4, 1, -1 do	
		-- table3Index = table3Index + (newXtable[tableIndex] * (math.pow(2, (5 - tableIndex))))
    -- end
	
	-- offSetForTable3 = offsetForTable2 + table3Index
	
	
    --console.log(ytable)
	--console.log(xtable)
	-- console.log(table1Index)
	-- console.log(newYtable)
    -- console.log(table2Index)
	-- console.log(byteForTable2)
	-- console.log(offsetForTable2)
	-- console.log(newXtable)
	-- console.log(table3Index)
	-- console.log(offSetForTable3)
	
--actual tile should be at 0x010000 + offSetForTable3

	emu.frameadvance();
	
end
