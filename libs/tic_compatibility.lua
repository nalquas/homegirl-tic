
--Nalquas' TIC-80 compatibility layer (2019-08-04)
--Highly incomplete, but interesting nonetheless.

homegirlfont = text.loadfont("sys:/fonts/Victoria.8b.gif")
homegirltime = 0

function startCompatibility()
	sys.stepinterval(1000/60) --60fps
	scrn = view.newscreen(10, 4) --320x180, the closest resolution to TIC-80's 240x136
end

function _step(t)
	homegirltime = t
	
	TIC()
	--TODO Execute SCN() and OVR()
	
	rect(0,136,320,44,0) --Bottom black area
	rect(240,0,240,180,0) --Right black area
	
	--Compatibility usage notice (to use free space on screen)
	gfx.fgcolor(15)
	text.draw("Nalquas' TIC-80 compatibility layer",homegirlfont,2,150)
	
	--Check if we have to exit
	if input.hotkey() == "\x1b" then
		sys.exit(0)
	end
end

function btn(id)
	--TODO This does not seem to work quite yet. Fix required.
	btnmap = input.gamepad(0)
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
