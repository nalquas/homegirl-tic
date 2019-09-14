
--Nalquas' TIC-80 compatibility layer (2019-09-14)
--Highly incomplete, but interesting nonetheless.
--Can only load .lua scripts at this point.
--Should you wish to run a program saved in a .tic file,
--you'll have to extract the script out of it and put it in a .lua file.
--Keep in mind that textures and sound cannot be used yet.


--MIT License
--
--Copyright (c) 2019 Nalquas
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.


drive_sys = _DRIVE
if drive_sys == "USER:" then drive_sys="SYS:" end
homegirlfont = text.loadfont(drive_sys .. "fonts/Victoria.8b.gif")

homegirlprint = print --Rename homegirl's print in order to not interfere with TIC-80's print
homegirltime = 0
homegirl_lastStep = 0
homegirl_lastFPSflush = 0
homegirlfps_accum = 0
homegirlfps = 0

function _init(args)
	homegirlprint(args)
	if #args==1 then
		--Initialize screen
		sys.stepinterval(1000/60) --60fps
		scrn = view.newscreen(10, 4) --320x180, the closest resolution to TIC-80's 240x136
		
		--Load TIC-80 palette (DB16)
		overwriteGfxPaletteAuto(0, 0x14, 0x0c, 0x1c) --black
		overwriteGfxPaletteAuto(1, 0x44, 0x24, 0x34) --dark red
		overwriteGfxPaletteAuto(2, 0x30, 0x34, 0x6d) --dark blue
		overwriteGfxPaletteAuto(3, 0x4e, 0x4a, 0x4f) --dark gray
		overwriteGfxPaletteAuto(4, 0x85, 0x4c, 0x30) --brown
		overwriteGfxPaletteAuto(5, 0x34, 0x65, 0x24) --dark green
		overwriteGfxPaletteAuto(6, 0xd0, 0x46, 0x48) --red
		overwriteGfxPaletteAuto(7, 0x75, 0x71, 0x61) --light gray
		overwriteGfxPaletteAuto(8, 0x59, 0x7d, 0xce) --light blue
		overwriteGfxPaletteAuto(9, 0xd2, 0x7d, 0x2c) --orange
		overwriteGfxPaletteAuto(10, 0x85, 0x95, 0xa1) --blue/gray
		overwriteGfxPaletteAuto(11, 0x6d, 0xaa, 0x2c) --light green
		overwriteGfxPaletteAuto(12, 0xd2, 0xaa, 0x99) --peach
		overwriteGfxPaletteAuto(13, 0x6d, 0xc2, 0xca) --cyan
		overwriteGfxPaletteAuto(14, 0xda, 0xd4, 0x5e) --yellow
		overwriteGfxPaletteAuto(15, 0xde, 0xee, 0xd6) --white
		
		loadfile(args[1])()
	else
		homegirlprint("Invalid usage. Correct usage: tic [filename]")
		sys.exit(0)
	end
end

function overwriteGfxPaletteAuto(id, r, g, b)
	gfx.palette(id, r/16, g/16, b/16)
end

function _step(t)
	homegirltime = t
	
	TIC()
	if SCN then SCN() end --TODO Somehow make this work for every individual line. Probably impossible.
	if OVR then OVR() end
	
	rect(0,136,320,44,0) --Bottom black area
	rect(240,0,240,180,0) --Right black area
	
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
	gfx.fgcolor(color)
	text.draw(txt, homegirlfont, x, y)
	
	return 0 --TODO width
end

function font(text, x, y, colorkey, char_width, char_height, fixed, scale)
	--TODO
	return print(text, x, y, 15, fixed, scale, false) --Temporary use: Translate to print in hope that it results in roughly the same result.
end

function clip(x, y, w, h)
	--TODO
	pass()
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
	--TODO Find an efficient and accurate way to fill a circle (Bresenham's algorithm?)
	
	--Inefficient, but accurate approach
	for i=radius,0,-1 do
		circb(x, y, i, color)
	end
	
	--Inaccurate, but relatively fast approach
	--gfx.fgcolor(color)
	--for i=0,359 do
	--	x_now = x+radius*math.cos(math.rad(i))
	--	y_now = y+radius*math.sin(math.rad(i))
	--	gfx.line(x,y,x_now,y_now)
	--end
end

function circb(x, y, radius, color)
	gfx.fgcolor(color)
	local x_last = x
	local y_last = y
	for i=0,360,2 do --Only check every second degree to improve performance
		x_now = x+radius*math.cos(math.rad(i))
		y_now = y+radius*math.sin(math.rad(i))
		if i>0 then gfx.line(x_last,y_last,x_now,y_now) end
		x_last = x_now
		y_last = y_now
	end
end

function spr(id, x, y, colorkey, scale, flip, rotate, w, h)
	--TODO
	pass()
end

function btn(id)
	--TODO Does not work for multiple players yet.
	local btnmap = input.gamepad(0)
	if id == 3 then
		return (btnmap & 1) > 0
	elseif id == 2 then
		return (btnmap & 2) > 0
	elseif id == 0 then
		return (btnmap & 4) > 0
	elseif id == 1 then
		return (btnmap & 8) > 0
	elseif id == 6 then
		return (btnmap & 16) > 0
	elseif id == 7 then
		return (btnmap & 32) > 0
	elseif id == 5 then
		return (btnmap & 64) > 0
	elseif id == 4 then
		return (btnmap & 128) > 0
	end
	return (btnmap & (2^id)) > 0
end

function btnp(id, hold, period)
	--TODO Not implemented yet. For now, we'll just pass btn() through.
	pass()
	return btn(id) --Pressed just now?
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
	--TODO
	pass()
end

function mget(x, y)
	--TODO
	pass()
	return 0 --id
end

function mset(x, y, id)
	--TODO
	pass()
end

function music(track, frame, row, loop)
	--TODO
	pass()
end

function peek(addr)
	--TODO
	pass()
	return 0 --val
end

function poke(addr, val)
	--TODO
	pass()
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
	--TODO This is so far away from my knowledge that it will probably never be implemented. Still putting it here so the code at least runs, even if textri() doesn't do anything
	pass()
	tri(x1, y1, x2, y2, x3, y3, 14)
end

function exit()
	sys.exit(0)
end

function pass()
	print("Called unimplemented function")
end
