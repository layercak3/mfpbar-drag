--[[
	This file is part of mfpbar.
	
	mfpbar is free software: you can redistribute it and/or modify it
	under the terms of the GNU Affero General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	mfpbar is distributed in the hope that it will be useful, but WITHOUT
	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
	for more details.
	
	You should have received a copy of the GNU Affero General Public License
	along with mfpbar. If not, see <https://www.gnu.org/licenses/>.
]]

local msg = require('mp.msg')
local utils = require('mp.utils')
local mpopt = require('mp.options')

-- globals

local state = {
	osd = nil,
	dpy_w = 0,
	dpy_h = 0,
	pbar_isactive = false,
	pbar_isminimized = true,
	mouse = nil,
	cached_ranges = nil,
	duration = nil,
	chapters = nil,
	timeout = nil,
	thumbfast = {
		width = 0,
		height = 0,
		disabled = true,
		available = false
	},
}

-- TODO: allow option to disable minimized bar when fullscreen ?
local opt = {
	pbar_height = 2,
	pbar_minimized_height = 0.5,
	pbar_color = "CCCCCC",
	cachebar_height = 0.24,
	cachebar_color = "1C6C89",
	hover_bar_color = "BDAE93",
	font_size = 16,
	font_pad = 4, -- TODO: rename this to hpad ?
	-- TODO: add a configurable vpad as well ?
	font_border_width = 2,
	font_border_color = "000000",
	proximity = 40,
	preview_border_width = 2,
	preview_border_color = "BDAE93",
	chapter_marker_size = 3,
	chapter_marker_color = "BDAE93",
	chapter_marker_border_width = 1,
	chapter_marker_border_color = "161616",
	autohide = 3,
}

-- function implementation

-- ASS uses BBGGRR format, which fucking sucks
function rgb_to_ass(color)
	if not string.len(color) == 6 then
		msg.error("Invalid color: " .. color)
		return "FFFFFF"
	end
	local r = string.sub(color, 1, 2)
	local g = string.sub(color, 3, 4)
	local b = string.sub(color, 5, 6)
	return string.upper(b .. g .. r)
end

function grab_chapter_name_at(sec)
	assert(state.chapters)
	local name = nil
	local psec = -1
	for _, c in ipairs(state.chapters) do
		if sec > c.time then
			name = c.title
		end
		assert(psec < c.time)
		psec = c.time
	end
	return name
end

function format_time(t)
	local h = math.floor(t / (60 * 60))
	t = t - (h * 60 * 60)
	local m = math.floor(t / 60)
	local s = t - (m * 60)
	return string.format("%.2d:%.2d:%.2d", h, m, s)
end

function round(n)
	assert(n >= 0)
	return math.floor(n + 0.5)
end

function render()
	state.osd:update()
	state.osd.data = nil
end

function draw_append(text)
	if state.osd.data == nil then
		state.osd.data = text
	else
		state.osd.data = state.osd.data .. '\n' .. text
	end
end

function draw_rect_point(x0, y0, x1, y1, x2, y2, x3, y3, color, opt)
	local s = '{\\pos(0, 0)}'
	opt = opt or {}
	s = s .. '{\\1c&' .. color .. '&}'
	s = s .. '{\\1a&' .. (opt.alpha or "00") .. '&}'
	s = s .. '{\\bord' .. (opt.bw or '0') .. '}'
	s = s .. '{\\3c&' .. (opt.bcolor or "000000") .. '&}'
	s = s .. string.format(
		'{\\p1}m %d %d l %d %d %d %d %d %d{\\p0}',
		x0, y0, x1, y1, x2, y2, x3, y3
	)
	draw_append(s)
end

function draw_rect(x, y, w, h, color, opt)
	draw_rect_point(
		x,      y,
		x + w,  y,
		x + w,  y + h,
		x,      y + h,
		color, opt
	)
end

function draw_text(x, y, size, text, opt)
	local s = string.format('{\\pos(%d, %d)}{\\fs%d}', x, y, size)
	opt = opt or {}
	s = s .. '{\\bord' .. (opt.bw or '0') .. '}'
	s = s .. '{\\3c&' .. (opt.bcolor or "000000") .. '&}'
	s = s .. text
	draw_append(s)
end

-- TODO: make this less janky.
function pbar_draw()
	local dpy_w = state.dpy_w
	local dpy_h = state.dpy_h
	local ypos = 0
	local p = mp.get_property_native("percent-pos")

	assert(state.pbar_isactive or state.pbar_isminimized)

	if p == nil or dpy_w == 0 or dpy_h == 0 then
		return
	end

	local fs = opt.font_size
	local pad = opt.font_pad
	local time = mp.get_property_osd("time-pos", "00:00:00")
	local trem = mp.get_property_osd("time-remaining", "99:00:00")
	local duration = state.duration
	local clist = state.chapters

	-- L0: playback cursor
	local pb_h = state.pbar_isminimized and opt.pbar_minimized_height or opt.pbar_height
	assert(pb_h > 0)
	pb_h = dpy_h * (pb_h / 100)
	pb_h = math.max(round(pb_h), 4)
	draw_rect(0, dpy_h - (pb_h + ypos), dpy_w * (p/100.0), pb_h, opt.pbar_color)
	ypos = ypos + pb_h

	if duration then
		-- L1: cache cusor
		if state.cached_ranges and opt.cachebar_height > 0 then
			assert(#state.cached_ranges > 0)
			local ch = dpy_h * (opt.cachebar_height / 100)
			ch = math.max(round(ch), 2)
			for _, range in ipairs(state.cached_ranges) do
				local s = range['start']
				local e = range['end']
				local sp = dpy_w * (s / duration)
				local ep = (dpy_w * (e / duration)) - sp

				draw_rect(sp, dpy_h - (ch + ypos), ep, ch, opt.cachebar_color)
			end
			ypos = ypos + ch
		end

		-- L0-???: chapters
		if clist and opt.chapter_marker_size > 0 then
			assert(#clist > 0)
			local bw = opt.chapter_marker_border_width
			local tw = opt.chapter_marker_size
			local miny = tw + bw + 1 -- +1 for pad
			local y = dpy_h - math.max(pb_h / 2, miny)
			for _, c in ipairs(clist) do
				local x = dpy_w * (c.time / duration)
				draw_rect_point(
					x - tw,  y,
					x,       y - tw,
					x + tw,  y,
					x,       y + tw,
					opt.chapter_marker_color,
					{ bw = bw, bcolor = opt.chapter_marker_border_color }
				)
			end
			ypos = math.max(ypos, dpy_h - (y + tw + bw))
		end
	end

	if not state.pbar_isminimized then
		-- L2: timeline
		local fopt = { bw = opt.font_border_width, bcolor = opt.font_border_color }
		-- LHS: current playback position
		draw_text(pad, dpy_h - (ypos + fs), fs, time, fopt)
		-- TODO: options to select what to display on the RHS
		-- RHS: time remaining
		draw_text(dpy_w - pad, dpy_h - (ypos + fs), fs, "{\\an9}-" .. trem, fopt)
		ypos = ypos + fs + (fopt.bw * 2)

		if duration then
			assert(state.mouse)

			-- L0-2: hovered timeline
			local hover_sec = duration * ((state.mouse.x + 0.5) / dpy_w)
			local hover_text = format_time(hover_sec)
			draw_rect(
				math.max(state.mouse.x - 1, 0), dpy_h - ypos,
				2, ypos, opt.hover_bar_color
			)
			local fw = fs * 2 -- guesstimate ¯\_(ツ)_/¯
			local x = math.max(state.mouse.x, pad + fw)
			x = math.min(dpy_w - (pad + fw), x)
			draw_text(
				x, dpy_h - (ypos + fs), fs,
				"{\\an8}" .. hover_text, fopt
			)
			ypos = ypos + fs + (fopt.bw * 2)

			-- L3: chapter name
			local cname = clist and grab_chapter_name_at(hover_sec) or nil
			if cname then
				assert(cname)
				local fw = string.len(cname) * fs * 0.28 -- guesstimate again
				local x = math.max(state.mouse.x, pad + fw)
				x = math.min(dpy_w - (pad + fw), x)
				draw_text(
					x, dpy_h - (ypos + fs),
					fs, "{\\an8}" .. cname, fopt
				)
				ypos = ypos + fs + (fopt.bw * 2)
			end

			-- L4: preview thumbnail
			if not state.thumbfast.disabled then
				local pw = opt.preview_border_width
				local hpad = 4 + pw
				local tw = state.thumbfast.width
				local th = state.thumbfast.height
				local y = dpy_h - (ypos + th + pw)
				local x = state.mouse.x - (tw / 2)
				x = math.max(hpad, x)
				x = math.min(dpy_w - (hpad + tw), x)
				mp.commandv(
					"script-message-to", "thumbfast", "thumb",
					hover_sec, x, y
				)
				ypos = ypos + th + pw

				-- L4: preview border
				if pw > 0 then
					local c = opt.preview_border_color
					draw_rect(
						x, y, tw, th, "161616",
						{ alpha = "7F", bw = pw, bcolor = c }
					)
					ypos = ypos + pw
				end
			end
		end
	end

	render()
end

function pbar_update(mouse)
	local dpy_w = state.dpy_w
	local dpy_h = state.dpy_h

	if dpy_w == 0 or dpy_h == 0 then
		return
	end

	assert(dpy_w > 0)
	assert(dpy_h > 0)
	assert(mouse)

	-- TODO: ensure there's enough height to draw our stuff ?
	if mouse.hover and mouse.y > dpy_h - opt.proximity then
		state.pbar_isminimized = false
		state.pbar_isactive = true
		pbar_draw()
		mp.add_forced_key_binding('mbtn_left', 'pbar_pressed', pbar_pressed)
		mp.observe_property("time-pos", nil, pbar_draw)
		if state.timeout then
			assert(opt.autohide > 0)
			state.timeout:kill()
			state.timeout.timeout = opt.autohide
			state.timeout:resume()
		end
	elseif state.pbar_isactive then
		if opt.pbar_minimized_height > 0 then
			state.pbar_isactive = true
			state.pbar_isminimized = true
			pbar_draw()
		else
			assert(state.pbar_isactive)
			state.pbar_isactive = false
			state.pbar_isminimized = false
			-- clear everything
			state.osd.data = ''
			render()
			mp.unobserve_property(pbar_draw)
		end

		mp.remove_key_binding('pbar_pressed')
		state.mouse = nil
		if state.thumbfast.available then
			mp.commandv("script-message-to", "thumbfast", "clear")
		end
	end
end

function pbar_minimize()
	if not state.pbar_isminimized then
		-- HACK: send a fake mouse event
		pbar_update({ hover = false, y = -1 })
	end
end

function pbar_pressed()
	assert(state.mouse.hover)
	assert(state.pbar_isactive)
	if state.duration then
		local hover_sec = state.duration * ((state.mouse.x + 0.5) / state.dpy_w)
		mp.set_property("time-pos", hover_sec);
	end
end

function update_mouse_pos(kind, mouse)
	assert(kind == "mouse-pos")
	state.mouse = mouse
	pbar_update(mouse)
end

function set_dpy_size(kind, osd)
	assert(kind == "osd-dimensions")
	state.dpy_w     = osd.w
	state.osd.res_x = osd.w
	state.dpy_h     = osd.h
	state.osd.res_y = osd.h
end

function set_cache_state(kind, c)
	assert(kind == "demuxer-cache-state")
	if c == nil then
		state.cached_ranges = nil
	else
		local r = c['seekable-ranges']
		if #r > 0 then
			state.cached_ranges = r
		else
			state.cached_ranges = nil
		end
	end
end

function set_duration(kind, d)
	assert(kind == "duration")
	state.duration = d
end

function set_chapter_list(kind, c)
	assert(kind == "chapter-list")
	if c and #c > 0 then
		state.chapters = c
	else
		state.chapters = nil
	end
end

function set_thumbfast(json)
	local data = utils.parse_json(json)
	if type(data) ~= "table" or not data.width or not data.height then
		msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
	else
		state.thumbfast = data
	end
end

function master()
	mpopt.read_options(opt, "mfpbar")
	for k,v in pairs(opt) do
		if string.find(k, "_color$") then
			opt[k] = rgb_to_ass(v)
		end
	end

	-- TODO: don't obstruct with `console.lua` ?
	state.osd = mp.create_osd_overlay("ass-events")
	mp.observe_property("osd-dimensions", "native", set_dpy_size)
	mp.observe_property('demuxer-cache-state', 'native', set_cache_state)
	mp.observe_property('duration', 'native', set_duration)
	mp.observe_property('chapter-list', 'native', set_chapter_list)
	mp.register_script_message("thumbfast-info", set_thumbfast)

	-- NOTE: mouse-pos doesn't work mpv versions older than v33
	mp.observe_property("mouse-pos", "native", update_mouse_pos)
	if opt.autohide > 0 then
		state.timeout = mp.add_timeout(opt.autohide, pbar_minimize)
	end
	if opt.pbar_minimized_height > 0 then
		mp.observe_property("time-pos", nil, pbar_draw)
	end
end

master()
