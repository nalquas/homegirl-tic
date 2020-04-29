
-- Nalquas' TIC-80 compatibility layer
-- https://github.com/nalquas/homegirl-tic
-- Highly incomplete, but interesting nonetheless.
-- Can only load Lua scripts, sprites and maps at this point.
-- Should you wish to run a program saved in a .tic file,
-- you'll have to extract the data out of it and put it inside a folder.
-- Keep in mind that sound cannot be used yet.


-- MIT License
--
-- Copyright (c) 2019-2020 Nalquas
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


homegirlfont = text.loadfont("Victoria.8b.gif")
font_big = text.loadfont("tic_big.8b.gif") or text.loadfont("ruthenia_c.8.gif") or homegirlfont
font_small = text.loadfont("ruthenia_c.8.gif") or homegirlfont

homegirlprint = print --Rename homegirl's print in order to not interfere with TIC-80's print
homegirltime = 0
homegirl_lastStep = 0
homegirl_lastFPSflush = 0
homegirlfps_accum = 0
homegirlfps = 0
homegirl_clip_area = NIL
homegirl_buttonmap = NIL
homegirl_buttonmap_last = NIL
homegirl_spritesheet = NIL
homegirl_mapdata = NIL
homegirl_bordercolor = 0

function _init(args)
	homegirlprint(args)
	if #args==1 then
		--Initialize screen
		sys.stepinterval(1000/60) --60fps
		scrn = view.newscreen(10, 4) --320x180, the closest resolution to TIC-80's 240x136
		
		--Load TIC-80 default palette (DB16)
		overwriteGfxPaletteFromString("140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6")
		
		-- Call some initial methods to setup stuff
		clip()
		
		-- Load files
		local folderpath = ""
		local codename = "code.lua"
		if fs.isdir(args[1]) then
			-- Path leads to a folder, game likely inside
			folderpath = args[1] .. "/"
		else
			-- Path leads to a file, likely .lua
			codename = args[1]
		end
		
		if fs.isfile(folderpath .. "palette.data") then
			overwriteGfxPaletteFromString(fs.read(folderpath .. "palette.data"))
		end
			
		-- Try local data first, then look for defaults in user drive if needed
		if fs.isfile(folderpath .. "sprites.gif") then
			homegirl_spritesheet = image.load(folderpath .. "sprites.gif")
		elseif fs.isfile("user:tic_defaults/sprites.gif") then
			homegirl_spritesheet = image.load("user:tic_defaults/sprites.gif")
		else
			homegirlprint("No sprites.gif given, no default sprites.gif in user:tic_defaults. Generating empty spritesheet instead...")
			homegirl_spritesheet = image.new(128, 256, 8)
		end
		
		if fs.isfile(folderpath .. "world.map") then
			homegirl_mapdata = fs.read(folderpath .. "world.map")
		elseif fs.isfile("user:tic_defaults/world.map") then
			homegirl_mapdata = fs.read("user:tic_defaults/world.map")
		else
			homegirlprint("No world.map given, no default world.map in user:tic_defaults. Generating empty map instead...")
			homegirl_mapdata = ""
		end
		
		loadfile(folderpath .. codename)()
	else
		homegirlprint("Invalid usage. Correct usage: tic [folder]")
		sys.exit(0)
	end
end

function overwriteGfxPaletteFromString(pal)
	for id = 0,15 do
		local index = id * 6
		local color = pal:sub(index+1, index+6)
		local r = tonumber(color:sub(1,2), 16)
		local g = tonumber(color:sub(3,4), 16)
		local b = tonumber(color:sub(5,6), 16)
		overwriteGfxPaletteAuto(id, r, g, b)
	end
end

function overwriteGfxPaletteAuto(id, r, g, b)
	gfx.palette(id, r/16, g/16, b/16)
end

function _step(t)
	homegirltime = t
	
	-- Refresh buttonmap
	homegirl_buttonmap_last = homegirl_buttonmap
	homegirl_buttonmap = input.gamepad(0) -- TODO Does not work for multiple players yet.
	
	-- Call tic functions
	TIC()
	if SCN then SCN(0) end --TODO Somehow make this work for every individual line. Probably impossible.
	if OVR then OVR() end
	
	-- Handle clip()
	rect(0, 0, homegirl_clip_area.x, 180, homegirl_bordercolor) -- Left
	rect(homegirl_clip_area.x, 0, homegirl_clip_area.w, homegirl_clip_area.y, homegirl_bordercolor) -- Top
	rect(homegirl_clip_area.x+homegirl_clip_area.w, 0, 320-(homegirl_clip_area.x+homegirl_clip_area.w), 180, homegirl_bordercolor) -- Right
	rect(homegirl_clip_area.x, homegirl_clip_area.y+homegirl_clip_area.h, homegirl_clip_area.w, 180-(homegirl_clip_area.y+homegirl_clip_area.h), homegirl_bordercolor) -- Bottom
	
	-- Clip the view so that the 240x136 viewport of TIC-80 is enforced
	rect(0,136,320,44,homegirl_bordercolor) --Bottom black area
	rect(240,0,240,180,homegirl_bordercolor) --Right black area
	
	--Compatibility usage notice (to use free space on screen)
	gfx.fgcolor(15)
	text.draw("Nalquas' TIC-80 compatibility layer\nCurrent FPS: " .. homegirlfps .. "\nSteptime: " .. (t-homegirl_lastStep) .. "ms",homegirlfont,2,150)
	
	--Check if we have to exit
	if input.hotkey() == "\x1b" then
		sys.exit(0)
	end
	
	homegirlfps_accum = homegirlfps_accum + 1
	if t-homegirl_lastFPSflush>=1000 then
		homegirlfps = homegirlfps_accum
		homegirlfps_accum = 0
		homegirl_lastFPSflush = t
	end
	
	homegirl_lastStep = t
end

function print(txt, x, y, color, fixed, scale, smallfont)
	x = x or 0
	y = y or 0
	color = color or 15
	fixed = fixed or false
	scale = scale or 1
	smallfont = smallfont or false
	
	-- Select correct font
	local font_to_use = font_big
	if smallfont then
		font_to_use = font_small
	end
	
	gfx.fgcolor(color)
	local width, height = text.draw(txt, font_to_use, x, y)
	
	return width
end

function font(text, x, y, colorkey, char_width, char_height, fixed, scale)
	--TODO
	return print(text, x, y, 15, fixed, scale, false) --Temporary use: Translate to print in hope that it results in roughly the same result.
end

function clip(x, y, w, h)
	if x==NIL or y==NIL or w==NIL or h==NIL then
		homegirl_clip_area = {x=0, y=0, w=240, h=136}
	else
		homegirl_clip_area = {x=x, y=y, w=w, h=h}
	end
end

function cls(color)
	color = color or 0
	gfx.bgcolor(color)
	gfx.cls()
end

function pix(x, y, color)
	if color==NIL then
		return gfx.pixel(x, y)
	else
		gfx.pixel(x, y, color)
	end
end

function line(x0, y0, x1, y1, color)
	gfx.fgcolor(color)
	gfx.line(x0, y0, x1, y1)
end

function rect(x, y, w, h, color)
	gfx.fgcolor(color)
	gfx.bar(x, y, w, h)
end

function rectb(x, y, w, h, color)
	gfx.fgcolor(color)
	gfx.line(x,y,x+w,y) --top
	gfx.line(x+w,y,x+w,y+h) --right
	gfx.line(x,y+h,x+w,y+h) --bottom
	gfx.line(x,y,x,y+h) --left
end

function circ(x, y, radius, color)
	-- Use triangles to approximate a circle
	gfx.fgcolor(color)
	local x_now = x+radius*math.cos(math.rad(350))
	local y_now = y+radius*math.sin(math.rad(350))
	for i=0,350,10 do --Only check every tenth degree to improve performance
		x_last = x_now
		y_last = y_now
		x_now = x+radius*math.cos(math.rad(i))
		y_now = y+radius*math.sin(math.rad(i))
		gfx.tri(x, y, x_last, y_last, x_now, y_now)
	end
end

function circb(x, y, radius, color)
	gfx.fgcolor(color)
	local x_last = x
	local y_last = y
	for i=0,360,10 do --Only check every tenth degree to improve performance
		x_now = x+radius*math.cos(math.rad(i))
		y_now = y+radius*math.sin(math.rad(i))
		if i>0 then gfx.line(x_last,y_last,x_now,y_now) end
		x_last = x_now
		y_last = y_now
	end
end

function spr(id, x, y, colorkey, scale, flip, rotate, w, h)
	--TODO flip and rotate
	colorkey = colorkey or -1
	scale = scale or 1
	flip = flip or 0
	rotate = rotate or 0
	w = w or 1
	h = h or 1
	
	if type(id) ~= "number" then id = 0 end
	
	-- Handle transparency (colorkey)
	if colorkey >= 0 and colorkey <= 15 then
		image.bgcolor(homegirl_spritesheet[1], colorkey)
		image.copymode(3, true)
	else
		image.copymode(3, false)
	end
	
	image.draw(homegirl_spritesheet[1], x, y, (id % 16) * 8, (id // 16) * 8, scale * (w * 8), scale * (h * 8), w * 8, h * 8)
end

function btn(id)
	--TODO Does not work for multiple players yet.
	if id == 3 then
		return (homegirl_buttonmap & 1) > 0
	elseif id == 2 then
		return (homegirl_buttonmap & 2) > 0
	elseif id == 0 then
		return (homegirl_buttonmap & 4) > 0
	elseif id == 1 then
		return (homegirl_buttonmap & 8) > 0
	elseif id == 6 then
		return (homegirl_buttonmap & 16) > 0
	elseif id == 7 then
		return (homegirl_buttonmap & 32) > 0
	elseif id == 5 then
		return (homegirl_buttonmap & 64) > 0
	elseif id == 4 then
		return (homegirl_buttonmap & 128) > 0
	end
	return (homegirl_buttonmap & (2^id)) > 0
end

function btnp(id, hold, period)
	--TODO Does not work for multiple players yet.
	--TODO hold and period still need to be implemented
	if id == 3 then
		return (homegirl_buttonmap & 1) > 0 and not ((homegirl_buttonmap_last & 1) > 0)
	elseif id == 2 then
		return (homegirl_buttonmap & 2) > 0 and not ((homegirl_buttonmap_last & 2) > 0)
	elseif id == 0 then
		return (homegirl_buttonmap & 4) > 0 and not ((homegirl_buttonmap_last & 4) > 0)
	elseif id == 1 then
		return (homegirl_buttonmap & 8) > 0 and not ((homegirl_buttonmap_last & 8) > 0)
	elseif id == 6 then
		return (homegirl_buttonmap & 16) > 0 and not ((homegirl_buttonmap_last & 16) > 0)
	elseif id == 7 then
		return (homegirl_buttonmap & 32) > 0 and not ((homegirl_buttonmap_last & 32) > 0)
	elseif id == 5 then
		return (homegirl_buttonmap & 64) > 0 and not ((homegirl_buttonmap_last & 64) > 0)
	elseif id == 4 then
		return (homegirl_buttonmap & 128) > 0 and not ((homegirl_buttonmap_last & 128) > 0)
	end
	return (homegirl_buttonmap & (2^id)) > 0 and not ((homegirl_buttonmap_last & (2^id)) > 0)
end

function sfx(id, note, duration, channel, volume, speed)
	--TODO
	pass()
end

function key(code)
	--TODO
	pass()
	return false --Pressed?
end

function keyp(code, hold, period)
	--TODO
	pass()
	return false --Pressed just now?
end

function map(x, y, w, h, sx, sy, colorkey, scale, remap)
	--TODO scale and remap
	x = x or 0
	y = y or 0
	w = w or 30
	h = h or 17
	sx = sx or 0
	sy = sy or 0
	colorkey = colorkey or -1
	scale = scale or 1
	remap = remap or nil

	for drawy = 0, h do
		for drawx = 0, w do
			spr(mget(x + drawx, y + drawy), sx+(drawx * 8), sy+(drawy * 8), colorkey)
		end
	end
end

function mget(x, y)
	if x >= 0 and y >= 0 and x <= 239 and y <= 135 then
		local index = 240 * (y % 136) + (x % 240)
		return string.byte(homegirl_mapdata, math.tointeger(index + 1)) -- returns id
	else
		return 0
	end
end

function mset(x, y, id)
	if id >= 0 and id <= 255 then -- Check whether id is in range as TIC-80 seems to ignore invalid mset requests
		local index = 240 * (y % 136) + (x % 240)
		local pos = math.tointeger(index + 1)
		homegirl_mapdata = homegirl_mapdata:sub(1, pos-1) .. string.char(id) .. homegirl_mapdata:sub(pos+1)
	end
	
end

function music(track, frame, row, loop)
	--TODO
	pass()
end

function peek(addr) -- val is a byte
	-- Addresses taken from https://github.com/nesbox/TIC-80/wiki/RAM
	if addr < 0x03fc0 then
		-- SCREEN
		local val = 0
		for i=0,1 do
			local addr4 = (addr*2)+i
			if i == 0 then
				val = val + (math.floor(pix(addr4 % 240, math.floor(addr4 / 240))) << 4)
			else
				val = val + math.floor(pix(addr4 % 240, math.floor(addr4 / 240)))
			end
		end
		return val
	elseif addr < 0x03ff0 then
		-- TODO PALETTE
	elseif addr < 0x03ff8 then
		-- TODO PALETTE MAP
	elseif addr < 0x03ff9 then
		-- BORDER COLOR
		return homegirl_bordercolor
	elseif addr < 0x03ffb then
		-- TODO SCREEN OFFSET
	elseif addr < 0x03ffc then
		-- TODO MOUSE CURSOR
	elseif addr < 0x04000 then
		-- UNSPECIFIED RAM
	elseif addr < 0x06000 then
		-- TODO BG SPRITES (TILES)
	elseif addr < 0x08000 then
		-- TODO FG SPRITES
	elseif addr < 0x0ff80 then
		-- MAP
		local index = addr - 0x8000
		return mget(index % 240, math.floor(index / 240))
	elseif addr < 0x0ff84 then
		-- GAMEPADS
		return homegirl_buttonmap
	elseif addr < 0x0ff88 then
		-- MOUSE
		local x, y, btn = input.mouse()
		if addr == 0x0ff84 then
			-- X
			return x
		elseif addr == 0x0ff85 then
			-- Y
			return y
		elseif addr == 0x0ff86 then
			-- buttons
			return btn
		else
			-- TODO scroll
		end
	elseif addr < 0x0ff8c then
		-- TODO KEYBOARD
	elseif addr < 0x0ff9c then
		-- TODO UNSPECIFIED RAM
	elseif addr < 0x0ffe4 then
		-- TODO SOUND REGISTERS
	elseif addr < 0x100e4 then
		-- TODO WAVEFORMS
	elseif addr < 0x11164 then
		-- TODO SFX
	elseif addr < 0x13e64 then
		-- TODO MUSIC PATTERNS
	elseif addr < 0x13ffc then
		-- TODO MUSIC TRACKS
	elseif addr < 0x14000 then
		-- TODO MUSIC POS
	else
		-- OUT OF RAM
	end
	return 0
end

function poke(addr, val) -- val is a byte
	-- Addresses taken from https://github.com/nesbox/TIC-80/wiki/RAM
	if addr < 0x03fc0 then
		-- SCREEN
		for i=0,1 do
			local addr4 = (addr*2)+i
			local val4 = val
			if i == 0 then
				val4 = (math.floor(val) & 0xf0) >> 4
			else
				val4 = math.floor(val) & 0x0f
			end
			pix(addr4 % 240, math.floor(addr4 / 240), val4)
		end
	elseif addr < 0x03ff0 then
		-- TODO PALETTE
	elseif addr < 0x03ff8 then
		-- TODO PALETTE MAP
	elseif addr < 0x03ff9 then
		-- BORDER COLOR
		homegirl_bordercolor = val
	elseif addr < 0x03ffb then
		-- TODO SCREEN OFFSET
	elseif addr < 0x03ffc then
		-- TODO MOUSE CURSOR
	elseif addr < 0x04000 then
		-- UNSPECIFIED RAM
	elseif addr < 0x06000 then
		-- TODO BG SPRITES
	elseif addr < 0x08000 then
		-- TODO FG SPRITES
	elseif addr < 0x0ff80 then
		-- MAP
		local index = addr - 0x8000
		mset(index % 240, math.floor(index / 240), val)
	elseif addr < 0x0ff84 then
		-- GAMEPADS
	elseif addr < 0x0ff88 then
		-- MOUSE
	elseif addr < 0x0ff8c then
		-- KEYBOARD
	elseif addr < 0x0ff9c then
		-- TODO UNSPECIFIED RAM
	elseif addr < 0x0ffe4 then
		-- TODO SOUND REGISTERS
	elseif addr < 0x100e4 then
		-- TODO WAVEFORMS
	elseif addr < 0x11164 then
		-- TODO SFX
	elseif addr < 0x13e64 then
		-- TODO MUSIC PATTERNS
	elseif addr < 0x13ffc then
		-- TODO MUSIC TRACKS
	elseif addr < 0x14000 then
		-- TODO MUSIC POS
	else
		-- OUT OF RAM
	end
end

function peek4(addr4)
	--TODO
	pass()
	return 0 --val4
end

function poke4(addr4, val)
	--TODO
	pass()
end

function reset()
	exit() --TODO There is no way to reset in homegirl this easily yet.
end

function memcpy(toaddr, fromaddr, length)
	--TODO
	pass()
end

function memset(addr, val, length)
	--TODO
	pass()
end

function pmem(index, val)
	if val==NIL then
		return 0 --val
	else
		--TODO Save
	end
end

function trace(msg, color)
	homegirlprint(tostring(msg))
end

function time()
	return homegirltime
end

function mouse()
	local x, y, btn = input.mouse()
	local left = btn&1 > 0
	local middle = btn&2 > 0
	local right = btn&3 > 0
	return x, y, left, middle, right
end

function sync(mask, bank, toCart)
	--TODO
	pass()
end

function tri(x1, y1, x2, y2, x3, y3, color)
	gfx.fgcolor(color)
	gfx.tri(x1, y1, x2, y2, x3, y3)
end

function textri(x1, y1, x2, y2, x3, y3, u1, v1, u2, v2, u3, v3, use_map, colorkey)
	--TODO use_map
	use_map = use_map or false
	colorkey = colorkey or -1
	
	-- Handle transparency (colorkey)
	if colorkey >= 0 and colorkey <= 15 then
		image.bgcolor(homegirl_spritesheet[1], colorkey)
		image.copymode(3, true)
	else
		image.copymode(3, false)
	end
	
	image.tri(homegirl_spritesheet[1], x1, y1, x2, y2, x3, y3, u1, v1, u2, v2, u3, v3)
end

function exit() -- Exit to cli
	sys.exit(0)
end

function pass()
	print("Called unimplemented function")
end
