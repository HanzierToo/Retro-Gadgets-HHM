-- Retro Gadgets

-- Code Written By:
--    Hanzier
-- Contact Me Here (Appropriately Comment/Message Before Adding Me):
-- 	 Discord: Hanzier#9779
--    Steam:   Hanzier

-- Special thanks to the Retro Gadgets Community for the help!

-- Initialize if game is valid
local gameState:boolean = true
local winState:boolean = false

-- Font Library For Game Over Screen
local font = gdt.ROM.System.SpriteSheets["StandardFont"]

-- Initializing the gadget and asset calls so we don't have to use the primitive calls.
local dpad:DPad = gdt.DPad0
local flBtn:LedButton = gdt.LedButton0
local rvBtn:LedButton = gdt.LedButton1
local vid:VideoChip = gdt.VideoChip0
local face:VideoChip = gdt.VideoChip1
local timer:VideoChip = gdt.VideoChip2
local speaker:Speaker = gdt.Speaker0
local audio:AudioChip = gdt.AudioChip0
local keyboard:KeyboardChip = gdt.KeyboardChip0

-- Initializing all necessary assets from assets folder.
local introSwitch:AudioSample = gdt.ROM.User.AudioSamples["intro_switch.wav"]
local gameOver:AudioSample = gdt.ROM.User.AudioSamples["game_over.wav"]
local explosion:AudioSample = gdt.ROM.User.AudioSamples["short_explosion.wav"]
local gameWin:AudioSample = gdt.ROM.User.AudioSamples["game_win.wav"]
local sprites:SpriteSheet = gdt.ROM.User.SpriteSheets["sprites_assets.png"]

-- Values used to draw the initial and whole board.
local x1:number = 0
local y1:number = 0
local x2:number = 8
local y2:number = 8

-- Determines where the cursor should be drawn.
local cursorX1:number = 0
local cursorY1:number = 0
local cursorX2:number = 8
local cursorY2:number = 8

-- Prevents buttons from being clicked more than once when held down.
-- See logic below in update()
local dpadXTicker:boolean = false
local dpadYTicker:boolean = false
local flagTicker:boolean = false
local revealTicker:boolean = false
local audioTicker:boolean = false
local introTicker:boolean = false

-- Board Logic Memory (Excluding Mines)
-- 0: Unrevealed
-- 1: Flagged
-- 2: Revealed
local boardStatus = {}
for i=0, 11 do
	boardStatus[i] = {}
	for j=0, 7 do
		boardStatus[i][j] = 0
	end
end

-- Mine Placement
local minePlaces = {}
for i=0, 11 do
	minePlaces[i] = {}
	for j=0, 7 do
		minePlaces[i][j] = "n"
	end
end

-- A round-about way of generating mines randomly and a way to determine difficulty.
-- n: No Mines
-- m: Mines
local mineChars = {"m","n","n","n","n","n","n","n","n","n"}

for i=0, 11 do
	for j=0, 7 do
		-- Lower the second number from 2-10 in the math.random func() to INCREASE difficulty.
		-- If you feel particularly masochistic, replace the "n"s with "m"s in mineChars{}.
		minePlaces[i][j] = mineChars[math.random(1,10)]
		write(tostring(minePlaces[i][j]).." ")
	end
	writeln("")
end

local adjacentMines:number = 0
math.clamp(adjacentMines, 0, 8)

-- Timer value
local secs:number = 0

-- Essential for win state check
-- Checks for the amount of unrevealed and revealed tiles.	
local unrevealed:number = 0
local revealed:number = 0

for i=0, 11 do
	for j=0, 7 do
		if(minePlaces[i][j] == "n" and boardStatus[i][j] == 0) then
			unrevealed += 1
		end
	end
end
log(tostring(unrevealed))

-- update function is repeated every time tick
function update()

	if(not introTicker) then
		audio:Play(introSwitch, 0)
		sleep(0.8)
		vid:DrawText(vec2(29,24), font, "Made By:", color.white, color.clear)
		vid:DrawText(vec2(29,32), font, "Hanzier", color.white, color.clear)
		sleep(2.2)
		introTicker = true
	end

	if(gameState and not winState) then
	
		
	
		-- Programs the light to turn on when clicked.
		flBtn.LedState = flBtn.ButtonState
		rvBtn.LedState = rvBtn.ButtonState

		-- Initializes the whole board by loading all the unrevealed tile sprites.
		for i=1, 8 do
			for j=1, 12 do
				vid:DrawSprite(vec2(x1,y1), sprites, 0, 1, color.white, color.clear)
				x1 += 8
				x2 += 8
			end
			x1 = 0
			x2 = 8
			y1 += 8
			y2 += 8
		end
	
	
		-- Cursor Initializer
		vid:DrawRect(vec2(x1,y1),vec2(x2,y2), color.red)
	
		-- Face Logic (Small Screen)
		face:DrawSprite(vec2(0,0), sprites, 0,2, color.white, color.clear)
		face:DrawSprite(vec2(8,0), sprites, 1,2, color.white, color.clear)
		face:DrawSprite(vec2(0,8), sprites, 0,3, color.white, color.clear)
		face:DrawSprite(vec2(8,8), sprites, 1,3, color.white, color.clear)
	
		-- All these tickers are needed to prevent the button logic from triggering more than once.
		-- Aptly, their names "ticker" have nothing to do with ticking, I just suck at naming :D
		if(dpad.X == 0) then
			dpadXTicker = false
		end
	
		if(dpad.Y == 0) then
			dpadYTicker = false
		end
	
		if(not flBtn.ButtonState) then
			flagTicker = false
		end
	
		if(not rvBtn.ButtonState) then
			revealTicker = false
		end
	
		-- God forgive me for the jank that is the code below.
		-- The code below functions to cross-check between the flag 2D array and the actual field.
		-- It programs the function of adding and removing the flag marking on a tile.
		if(flBtn.ButtonState and not flagTicker and boardStatus[cursorX1/8][cursorY1/8] == 0) then
			boardStatus[cursorX1/8][cursorY1/8] = 1
			flagTicker = true
		elseif(flBtn.ButtonState and not flagTicker and boardStatus[cursorX1/8][cursorY1/8] == 1) then
			boardStatus[cursorX1/8][cursorY1/8] = 0
			flagTicker = true
		end
		-- Inefficient for loop that iterates through the whole board every update, but it
		-- allows us to bypass the clearScreen() function which is poorly written.
		-- Jank Begets Jank
		for i=0, 11 do
			for j=0, 7 do
				if(boardStatus[i][j] == 1) then
					vid:DrawSprite(vec2(i*8,j*8), sprites, 0, 0, color.white, color.clear)
				elseif(boardStatus[i][j] == 0) then
					vid:DrawSprite(vec2(i*8,j*8), sprites, 0, 1, color.white, color.clear)
					vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
				end
			end
		end
		-- End of flag logic
	
		-- Similar to the flag logic above, this handles the primitive revealed tile logic.
		-- Revealed tiles cannot be unrevealed, tiles with flags on them cannot be assigned
		-- to be flagged, and vice versa.
		if(rvBtn.ButtonState and not revealTicker and boardStatus[cursorX1/8][cursorY1/8] == 0) then
			boardStatus[cursorX1/8][cursorY1/8] = 2
			flagTicker = true
		end
			
		if(rvBtn.ButtonState) then
			face:DrawSprite(vec2(0,0), sprites, 2,4, color.white, color.clear)
			face:DrawSprite(vec2(8,0), sprites, 3,4, color.white, color.clear)
			face:DrawSprite(vec2(0,8), sprites, 2,5, color.white, color.clear)
			face:DrawSprite(vec2(8,8), sprites, 3,5, color.white, color.clear)
		end
					
		for i=0, 11 do
			for j=0, 7 do
				if(minePlaces[i][j] == "n") then
					if(boardStatus[i][j] == 2) then
						vid:DrawSprite(vec2(i*8,j*8), sprites, 1, 0, color.white, color.clear)
											
						adjacentMines = 0
						
						if(i > 0 and j > 0 and i < 11 and j < 7) then
							if(minePlaces[i-1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
						elseif(i == 0 and j > 0 and j < 7) then
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
						elseif(i == 11 and j > 0 and j < 7) then
							if(minePlaces[i-1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
						elseif(j == 0 and i > 0 and i < 11) then
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j+1] == "m") then
								adjacentMines += 1
							end
						elseif(j == 7 and i > 0 and i < 11) then
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j-1] == "m") then
								adjacentMines += 1
							end
						elseif(i == 0 and j == 0) then
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
						elseif(i == 0 and j == 7) then
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i+1][j] == "m") then
								adjacentMines += 1
							end
						elseif(i == 11 and j == 0) then
							if(minePlaces[i][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j+1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
						elseif(i == 11 and j == 7) then
							if(minePlaces[i][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j-1] == "m") then
								adjacentMines += 1
							end
							if(minePlaces[i-1][j] == "m") then
								adjacentMines += 1
							end
						end
						
						print(adjacentMines)
						
						-- The SUPERIOR WinXP Minesweeper color scheme
						clrarr = {
							{0,0,225},		-- blue 1
							{41,137,41},	-- green 2
							{255,0,0},		-- red 3
							{0,0,123},		-- dark blue 4
							{123,0,0},		-- dark red 5
							{0,123,123},	-- faded green 6
							{0,0,0},			-- black 7
							{113,113,113} -- grey 8
						}
						
						if(adjacentMines > 0) then
							vid:DrawText(vec2(i*8+2,j*8),
								font,
								tostring(adjacentMines),
								Color( -- this just helps to determine color of number
									clrarr[adjacentMines][1],
									clrarr[adjacentMines][2],
									clrarr[adjacentMines][3]
								),
								color.clear)
						end
					elseif(boardStatus[i][j] == 0) then
						vid:DrawSprite(vec2(i*8,j*8), sprites, 0, 1, color.white, color.clear)
						vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
					end
					
				elseif(minePlaces[i][j] == "m") then
					if(boardStatus[i][j] == 2) then
						vid:DrawSprite(vec2(i*8,j*8), sprites, 1, 1, color.white, color.clear)
						audio:Play(explosion,0)
						gameState = false
					elseif(boardStatus[i][j] == 0) then
						vid:DrawSprite(vec2(i*8,j*8), sprites, 0, 1, color.white, color.clear)
						vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
					end
				end
			end
		end
		
		-- End of reveal logic
			
		-- Win state checker
		revealed = 0
		for i=0, 11 do
			for j=0, 7 do
				if(minePlaces[i][j] == "n" and boardStatus[i][j] == 2) then					
					revealed += 1
				end
			end
		end	
				
		if(unrevealed - revealed == 0) then
			winState = true
			gameState = false
		end
	
		-- Right DPad Handler
		if(dpad.X == 100 and not dpadXTicker) then
			clearScreen()
			
			if(cursorX1 == 88 and cursorX2 == 96) then
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			else
				cursorX1 += 8
				cursorX2 += 8
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			end
			dpadXTicker = true
		end
	
		-- Left DPad Handler
		if(dpad.X == -100 and not dpadXTicker) then
			clearScreen()
		
			if(cursorX1 == 0 and cursorX2 == 8) then
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			else
				cursorX1 -= 8
				cursorX2 -= 8
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			end
			dpadXTicker = true
		end
	
	
		-- Up DPad Handler
		if(dpad.Y == 100 and not dpadYTicker) then
			clearScreen()
			
			if(cursorY1 == 0 and cursorY2 == 8) then
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			else
				cursorY1 -= 8
				cursorY2 -= 8
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			end
			dpadYTicker = true
		end
	
	
		-- Down DPad Handler
		if(dpad.Y == -100 and not dpadYTicker) then
			clearScreen()
			
			if(cursorY1 == 56 and cursorY2 == 64) then
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			else
				cursorY1 += 8
				cursorY2 += 8
				vid:DrawRect(vec2(cursorX1,cursorY1),vec2(cursorX2,cursorY2), color.red)
			end
		
			dpadYTicker = true
	
		end
			
		elseif(not gameState and not winState) then
			face:DrawSprite(vec2(0,0), sprites, 0,4, color.white, color.clear)
			face:DrawSprite(vec2(8,0), sprites, 1,4, color.white, color.clear)
			face:DrawSprite(vec2(0,8), sprites, 0,5, color.white, color.clear)
			face:DrawSprite(vec2(8,8), sprites, 1,5, color.white, color.clear)
			sleep(3)
			clearScreen()
			if(not audioTicker) then
				audio:Play(gameOver, 0)
				audioTicker = true
			end
			vid:DrawText(vec2(24,28), font, "Game Over!", color.white, color.clear)
		
		else
			face:DrawSprite(vec2(0,0), sprites, 2,2, color.white, color.clear)
			face:DrawSprite(vec2(8,0), sprites, 3,2, color.white, color.clear)
			face:DrawSprite(vec2(0,8), sprites, 2,3, color.white, color.clear)
			face:DrawSprite(vec2(8,8), sprites, 3,3, color.white, color.clear)
			sleep(3)
			clearScreen()
			if(not audioTicker) then
				audio:Play(gameWin, 0)
				audioTicker = true
			end
			vid:DrawText(vec2(27,28), font, "You Win!", color.white, color.clear)
		end
end

-- Look, I know it's a scuffed way of clearing the red cursor trail, but it works.
function clearScreen()

	vid:Clear(color.clear)
		
		x1 = 0
		y1 = 0
		x2 = 8
		y2 = 8
			
		if(gameState) then
			for i=1, 8 do
				for j=1, 12 do
					vid:DrawSprite(vec2(x1,y1), sprites, 0, 1, color.white, color.clear)
					x1 += 8
					x2 += 8
				end
				x1 = 0
				x2 = 8
				y1 += 8
				y2 += 8
			end
		end
end