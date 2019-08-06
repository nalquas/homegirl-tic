
--Nalquas' TIC-80 compatibility layer (2019-08-04)
--Highly incomplete, but interesting nonetheless.

homegirlfont = text.loadfont("sys:/fonts/Victoria.8b.gif")
homegirltime = 0
homegirl_lastStep = 0
homegirl_lastFPSflush = 0
homegirlfps_accum = 0
homegirlfps = 0

function startCompatibility()
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
end

function _step(t)
	homegirltime = t
	
	TIC()
	--TODO Execute SCN() and OVR()
	
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

function overwriteGfxPaletteAuto(id, r, g, b)
	gfx.palette(id, r/16, g/16, b/16)
end

function mouse()
	x, y, btn = input.mouse()
	if btn>0 then btn=true else btn=false end
	return x, y, btn, false, false --TODO Homegirl only has left click right now. Implement later.
end

function btn(id)
	--TODO Does not work for multiple players yet.
	btnmap = input.gamepad(0)
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

function reset()
	exit() --TODO There is no way to reset in homegirl this easily yet.
end

function exit()
	sys.exit(0)
end

function trace(msg, color)
	--TODO Print msg to console. Probably not possible while also overriding print()
end

function time()
	return homegirltime
end

function pix(x, y, color)
	if color==NIL then
		return pixel(x, y)
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
	--for i=radius,0,-1 do
	--	circb(x, y, i, color)
	--end
	
	--Inaccurate, but relatively fast approach
	gfx.fgcolor(color)
	for i=0,359 do
		x_now = x+radius*math.cos(math.rad(i))
		y_now = y+radius*math.sin(math.rad(i))
		gfx.line(x,y,x_now,y_now)
	end
end

function circb(x, y, radius, color)
	gfx.fgcolor(color)
	x_last = x
	y_last = y
	for i=0,360 do
		x_now = x+radius*math.cos(math.rad(i))
		y_now = y+radius*math.sin(math.rad(i))
		if i>0 then gfx.line(x_last,y_last,x_now,y_now) end
		x_last = x_now
		y_last = y_now
	end
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
	return width
end

function cls(color)
	color = color or 0
	gfx.bgcolor(color)
	gfx.cls()
end
