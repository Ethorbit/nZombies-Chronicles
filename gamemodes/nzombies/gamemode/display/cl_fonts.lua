//Main Text
surface.CreateFont("BigHP", {
    font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    size = 38
})

surface.CreateFont("SmallHP", {
    font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    size = 30
})

surface.CreateFont( "nz.display.hud.main", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 48,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.small", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 28,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.smaller", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 22,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.tiny", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 14,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.small.local", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 31,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.medium", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 36,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.points", {
	font = "Default",
	size = 20,
	weight = 5000,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.ammo", {
	font = "Calibri",
	size = 60,
	weight = 50,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.ammo2", {
	font = "Calibri",
	size = 40,
	weight = 50,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.ammo3", {
	font = "Calibri",
	size = 20,
	weight = 50,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.ammo4", {
	font = "Calibri",
	size = 15,
	weight = 50,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.smaller", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 18,
	weight = 300,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.rounds", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 160,
	weight = 30,
	antialias = true,
} )

surface.CreateFont( "nz.display.hud.rounds.small", {
	font = "DK Umbilical Noose", //Avenir Next
	size = 100,
	weight = 30,
	antialias = true,
} )

hook.Add("InitPostEntity", "MyLastTryToFixShit", function()
	local healthArmorVar = GetConVar("nzc_health_hud")
	local isBigSize = false
	local function HealthHudRoundResize()
		if healthArmorVar then
			if (!isBigSize and healthArmorVar:GetInt() == 4) then
				surface.CreateFont( "nz.display.hud.rounds", {
					font = "DK Umbilical Noose", //Avenir Next
					size = 190,
					weight = 30,
					antialias = true,
				} )

				isBigSize = true
			elseif (isBigSize) then
				surface.CreateFont( "nz.display.hud.rounds", {
					font = "DK Umbilical Noose", //Avenir Next
					size = 160,
					weight = 30,
					antialias = true,
				} )

				isBigSize = false
			end
		end
	end

	cvars.RemoveChangeCallback("nzc_health_hud", "HealthRoundResizerxd")
	cvars.AddChangeCallback("nzc_health_hud", function()
		HealthHudRoundResize()
	end, "HealthRoundResizerxd")

	HealthHudRoundResize()
end)

-- Rotated text function, as taken from the gmod wiki
local matscale = Vector(1,1,1)
function draw.TextRotatedScaled( text, x, y, color, font, ang, scaleX, scaleY )
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	surface.SetFont( font )
	surface.SetTextColor( color )
	surface.SetTextPos( 0, 0 )
	local textWidth, textHeight = surface.GetTextSize( text )
	local rad = -math.rad( ang )
	x = x - ( math.cos( rad ) * textWidth / 2 + math.sin( rad ) * textHeight / 2 )
	y = y + ( math.sin( rad ) * textWidth / 2 + math.cos( rad ) * textHeight / 2 )
	local m = Matrix()
	m:SetAngles( Angle( 0, ang, 0 ) )
	m:SetTranslation( Vector( x, y, 0 ) )
	matscale.x = scaleX
	matscale.y = scaleY
	m:Scale(matscale)
	cam.PushModelMatrix( m )
		surface.DrawText( text )
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
end
