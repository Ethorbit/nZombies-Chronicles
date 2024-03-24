-- MIT License
--
-- Copyright (c) 2020 wised
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

-- (Originally created by Cryotheus, see it here: https://github.com/Cryotheus/nzombies_progress_bar)
-- (Modified by Ethorbit - integrated the networking into the core of nZombies to make this code a lot cleaner)
if SERVER then
	resource.AddSingleFile("materials/bar/bloodline_bar.png")
	resource.AddSingleFile("materials/bar/bloodline_bar_back.png")
end

if CLIENT then
	if nzProgressBar then return end
	nzProgressBar = {} -- This is now a part of the gamemode

	local bar_mat = Material("bar/bloodline_bar.png")
	local bar_mat_bg = Material("bar/bloodline_bar_back.png")

	local cvars_bar_enabled = 1
	local cvars_bar_text_enabled = 1
	local cvars_bar_text_y_pos = 5
	local cvars_bar_y = 5
	local prog_bar_active = false
	local scale = 0.5
	local scr_h =  ScrH()
	local scr_w = ScrW()
	local zombies_max = 0
	local zombies_killed = 0
	local zombies_killed_text = ""
	local zombies_killed_text_font = ""

	local pb_h = 0
	local pb_stencil_w = 0
	local pb_w = 0
	local pb_x = 0
	local pb_text_x = 0
	local pb_text_y = 0
	local pb_y = 0
	local pb_y_current_percent = 0
	local pb_y_current_percent_inc = engine.TickInterval()
	local pb_y_percent = 0
	local progress_current_percent = 0
	local progress_current_percent_inc = engine.TickInterval()
	local progress_percent = 0

	local font_data = {}

	CreateClientConVar("nz_progbar_enabled", "1", true, false, "Should the bar be renderd?", 0, 1)
	CreateClientConVar("nz_progbar_scale", "0.5", true, false, "Changes the size of the bar.", 0.05, 20)
	CreateClientConVar("nz_progbar_text_enabled", "1", true, false, "Should the text on the progress bar be renderd?", 0, 1)
	CreateClientConVar("nz_progbar_y_pos", "5", true, false, "The y position of the progress bar from the top of the screen.", 0, 65536)
	CreateClientConVar("nz_progbar_text_y_pos", "5", true, false, "The y position offset for the text, it is parented to the progress bar.", -65536, 65536)

	local function calc_vars()
		pb_w = scale * 930
		pb_h = scale * 66

		pb_x = scr_w * 0.5 - scale * 465
		pb_y = pb_y_current_percent * (pb_w + 20) - pb_w

		pb_text_x = scr_w * 0.5
		pb_text_y = pb_y + cvars_bar_text_y_pos * scale
	end

	calc_vars()

	local function create_font(size, weight)
		surface.CreateFont("pbgenfont" .. size .. "." .. weight, {
			font = "DK Umbilical Noose",
			size = size,
			weight = weight,
			antialias = true,
		})
	end

	local function register_font(size, weight)
		if font_data[size] then
			if font_data[size][weight] then return
			else
				font_data[size][weight] = true

				create_font(size, weight)
			end
		else
			font_data[size] = {[weight] = true}

			create_font(size, weight)
		end
	end

	local function set_font(size, weight)
		zombies_killed_text_font = "pbgenfont" .. size .. "." .. weight

		register_font(size, weight)
	end

	set_font(22, 300)

	--to keep the speed of the bar consistent
	local function calculate()
		--for the red part
		progress_current_percent = progress_current_percent < progress_percent and math.min(progress_current_percent + progress_current_percent_inc, progress_percent) or math.max(progress_current_percent - progress_current_percent_inc, progress_percent)
		pb_stencil_w = pb_x + progress_current_percent * pb_w

		--for the bar sliding up and down
		pb_y_current_percent = pb_y_current_percent < pb_y_percent and math.min(pb_y_current_percent + pb_y_current_percent_inc, pb_y_percent) or math.max(pb_y_current_percent - pb_y_current_percent_inc, pb_y_percent)
		pb_y = pb_y_current_percent * (pb_w * 0.5 + cvars_bar_y) - pb_w * 0.5
		pb_text_y = pb_y + cvars_bar_text_y_pos * scale

		if pb_y_current_percent == 0 then
			prog_bar_rendering = false

			hook.Remove("HUDPaint", "prog_bar_hudpaint_hook")
			hook.Remove("Tick", "prog_bar_tick_hook")
		end
	end

	--local cached_color_white = color_white

	--caching functions locally so we don't have to keep looking them up in _G
	local fl_draw_DrawText = draw.DrawText
	local fl_render_ClearStencil = render.ClearStencil
	local fl_render_SetStencilCompareFunction = render.SetStencilCompareFunction
	local fl_render_SetStencilEnable = render.SetStencilEnable
	local fl_render_SetStencilFailOperation = render.SetStencilFailOperation
	local fl_render_SetStencilPassOperation = render.SetStencilPassOperation
	local fl_render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local fl_render_SetStencilTestMask = render.SetStencilTestMask
	local fl_render_SetStencilWriteMask = render.SetStencilWriteMask
	local fl_render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local fl_surface_SetDrawColor = surface.SetDrawColor
	local fl_surface_SetMaterial = surface.SetMaterial
	local fl_surface_DrawRect = surface.DrawRect
	local fl_surface_DrawTexturedRect = surface.DrawTexturedRect

	--I also cached calculated values
	local function draw_bar()
		fl_surface_SetDrawColor(255, 255, 255, 255)
		fl_surface_SetMaterial(bar_mat_bg)
		fl_surface_DrawTexturedRect(pb_x, pb_y, pb_w, pb_h)

		fl_render_ClearStencil()
		fl_render_SetStencilEnable(true)
		fl_render_SetStencilCompareFunction(STENCIL_NEVER)
		fl_render_SetStencilPassOperation(STENCIL_KEEP)
		fl_render_SetStencilFailOperation(STENCIL_REPLACE)
		fl_render_SetStencilZFailOperation(STENCIL_KEEP)
		fl_render_SetStencilWriteMask(0xFF)
		fl_render_SetStencilTestMask(0xFF)
		fl_render_SetStencilReferenceValue(1)

		fl_surface_DrawRect(0, 0, pb_stencil_w, scr_h)

		fl_render_SetStencilCompareFunction(STENCIL_EQUAL)

		fl_surface_SetMaterial(bar_mat)
		fl_surface_DrawTexturedRect(pb_x, pb_y, pb_w, pb_h)

		fl_render_SetStencilEnable(false)

		if cvars_bar_text_enabled ~= 0 then fl_draw_DrawText(zombies_killed_text, zombies_killed_text_font, pb_text_x, pb_text_y, color_white, TEXT_ALIGN_CENTER) end
	end

	function nzProgressBar.Disable()
		pb_y_percent = 0
		prog_bar_active = false
	end

	function nzProgressBar.Enable()
		local enable_var = GetConVar("nz_progbar_enabled")
		if enable_var and enable_var:GetBool() then
			if not prog_bar_rendering then
				hook.Add("HUDPaint", "prog_bar_hudpaint_hook", draw_bar)
				hook.Add("Tick", "prog_bar_tick_hook", calculate)
			end

			pb_y_percent = 1
			prog_bar_active, prog_bar_rendering = true, true
		end
	end

	cvars.RemoveChangeCallback("nz_progbar_enabled", "nZProgBarEnabledCallback")
	cvars.AddChangeCallback("nz_progbar_enabled", function(name, old_value, new_value)
		cvars_bar_enabled = math.Round(new_value)

		if cvars_bar_enabled ~= 0 then nzProgressBar.Enable() else nzProgressBar.Disable() end
	end, "nZProgBarEnabledCallback")

	cvars.RemoveChangeCallback("nz_progbar_scale", "nZProgBarScaleCallback")
	cvars.AddChangeCallback("nz_progbar_scale", function(name, old_value, new_value)
		scale = new_value

		calc_vars()
		set_font(44 * scale, 300)
	end, "nZProgBarScaleCallback")

	cvars.RemoveChangeCallback("nz_progbar_text_enabled", "nZProgBarTextEnabledCallback")
	cvars.AddChangeCallback("nz_progbar_text_enabled", function(name, old_value, new_value)
		cvars_bar_text_enabled = math.Round(new_value)
		--
	end, "nZProgBarTextEnabledCallback")

	cvars.RemoveChangeCallback("nz_progbar_y_pos", "nZProgBarYPosCallback")
	cvars.AddChangeCallback("nz_progbar_y_pos", function(name, old_value, new_value)
		cvars_bar_y = new_value
		--
	end, "nZProgBarYPosCallback")


	cvars.RemoveChangeCallback("nz_progbar_text_y_pos", "nZProgBarTextYPosCallback")
	cvars.AddChangeCallback("nz_progbar_text_y_pos", function(name, old_value, new_value)
		cvars_bar_text_y_pos = new_value

		calc_vars()
	end, "nZProgBarTextYPosCallback")

	hook.Add("OnScreenSizeChanged", "prog_bar_screen_res_changed_hook", function() scr_h, scr_w = ScrH(), ScrW() end)
	hook.Add("OnRoundCreative", "prog_bar_onroundend_hook", function() nzProgressBar.Disable() end)
	hook.Add("OnRoundEnd", "prog_bar_onroundend_hook", function() nzProgressBar.Disable() end)
	hook.Add("OnRoundPreparation", "prog_bar_onroundprep_hook", function() nzProgressBar.Disable() end)
	hook.Add("OnRoundStart", "prog_bar_onroundstart_hook", function()
		progress_current_percent = 0
		progress_percent = 0

		nzProgressBar.Enable()
	end)

	hook.Add("NZ.UpdateZombiesMax", "NZUpdateProgressBarMaxZombies", function(num)
		zombies_max = nzRound:GetZombiesMax()

		local end_txt = zombies_max

		if nzRound:GetNumber() == -1 then -- Round Infinity support
			end_txt = "∞"
		end

		zombies_killed_text = "zombies killed  0 / " .. end_txt
	end)

	hook.Add("NZ.UpdateZombiesKilled", "NZUpdateProgressBarZombiesKilled", function(num)
		zombies_killed = num
		local end_txt = zombies_max

		if nzRound:GetNumber() == -1 then -- Round Infinity support
			end_txt = "∞"
		end

		zombies_killed_text = "zombies killed  " .. zombies_killed .. " / " .. end_txt
		progress_percent = zombies_killed / zombies_max
	end)
end
