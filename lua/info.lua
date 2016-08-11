--[[
This file is part of "New Life" which is released under GPL.
See file LICENCE or go to http://www.gnu.org/licenses/ for full license details.

New Life is a series of custom scripts for Conky, a system monitor, based on
torsmo.

Copyright (c) 2016 Gabriele N. Tornetta <phoenix1987@gmail.com>. All rights
reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

require 'cairo'
require 'lua.common'

--------------------------------------------------------------------------------
-- CONFIGURATION Section -------------------------------------------------------
--------------------------------------------------------------------------------

--[[
Table of conky option and label pairs. Adjust as needed.
]]
info = {
    {"${exec lsb_release -d | cut -f 2}",   "Distro"},
    {"${kernel}",                           "Kernel"},
    {"${exec uname -p}",                    "Arch"}
}

progress_bar = 1

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]

w = 720 --conky_window.width

wu_paths = "sun_phase.sunrise.hour "..
           "sun_phase.sunrise.minute " ..
           "sun_phase.sunset.hour " ..
           "sun_phase.sunset.minute"

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_date_time(cr)
    -- Vertical separator
    cairo_set_line_width(cr, 1)
    draw_segment(cr, conky_window.width / 2 - 64, 40,
                     conky_window.width / 2 + 64, 40)

    draw_segment(cr, conky_window.width / 2, 40,
                     conky_window.width / 2, 130)

    -- Clock
    cairo_set_font_size(cr, 52)
    write_bottom_right(cr, w / 2 - 16, 64, conky_parse("${time %H:%M}") )

    -- Weekday
    cairo_set_font_size(cr, 10)
    write_bottom_left(cr, w / 2 + 16, 58, conky_parse("${time %A}") )

    -- Date
    cairo_set_font_size(cr, 24)
    write_top_left(cr, w / 2 + 16, 90, conky_parse("${time %B %d}") )

    -- Year
    cairo_set_font_size(cr, 10)
    write_top_left(cr, w / 2 + 16, 108, conky_parse("${time %Y}") )
end

--------------------------------------------------------------------------------

function draw_progress(cr)
    local W = 320
    local t = 3
    local r = 10/4
    local y = 130

    data = conky_parse( "${exec python python/wu.py ".. wu_paths .. "}" )
    sun = string.split(data, "|")

    sunrise = (60 * sun[1] + sun[2]) / (60 * 24)
    sunset  = (60 * sun[3] + sun[4]) / (60 * 24)
    now = (60 * tonumber(conky_parse("${time %H}")) + tonumber(conky_parse("${time %M}"))) / (60 * 24)

    -- Background
    cairo_set_source_rgba(cr, 1, 1, 1, .2)
    cairo_rectangle(cr, (w - W) / 2, y, W, t)
    cairo_arc(cr, (w + W) / 2, y + t / 2, t / 2, -math.pi / 2, math.pi / 2)
    cairo_arc(cr, (w - W) / 2 + W * sunrise, y + t / 2, t*r, 0, math.pi * 2)
    cairo_arc(cr, (w - W) / 2 + W * sunset, y + t / 2, t*r, 0, math.pi * 2)
    cairo_fill(cr)

    -- Fill
    cairo_set_source_rgba(cr, 1, 1, 1, .8)
    cairo_arc(cr, (w - W) / 2, y + t / 2, t / 2, math.pi / 2, 3 / 2 * math.pi)
    cairo_rectangle(cr, (w - W) / 2, y, W * now, t)
    cairo_fill(cr)

    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    a = math.acos( math.min( math.max(-1, (sunrise - now) * W / t), 1 ) )
    cairo_arc(cr, (w - W) / 2 + W * sunrise, y + t / 2, t*r, math.pi - a, math.pi + a)
    --cairo_fill(cr)
    a = math.acos( math.min( math.max(-1, (sunset - now) * W / t), 1 ) )
    cairo_arc(cr, (w - W) / 2 + W * sunset, y + t / 2, t*r, math.pi - a, math.pi + a)
    cairo_fill(cr)

    -- Times
    cairo_set_font_size(cr, 10)
    write_center_middle(cr, (w - W) / 2 + W * sunrise, y + 2.5*t*r, sun[1] .. ":" .. sun[2])
    write_center_middle(cr, (w - W) / 2 + W * sunset, y + 2.5 * t *r, sun[3] .. ":" .. sun[4])

    -- Icons
    cairo_set_source_rgba(cr, .1, .1, .1, 1)
    cairo_arc(cr, (w - W) / 2 + W * sunrise, y + t/2  , t * 2/3 * r, -math.pi, 0)
    cairo_fill(cr)
    cairo_arc(cr, (w - W) / 2 + W * sunset, y + t / 2 , t * 2/3 * r, 0, math.pi)
    cairo_fill(cr)
end

--------------------------------------------------------------------------------

function draw_info(cr)
    local d = w / #info
    local y = 226
    local s = 22

    for entry = 1, #info do
        d = w / #info
        cairo_set_font_size(cr, 18)
        write_center_middle(cr, (entry - .5) * d, y, info[entry][2])

        cairo_set_font_size(cr, 10)
        write_center_middle(cr, (entry - .5) * d, y + s, conky_parse(info[entry][1]))
    end
end

--[[
Main function down here
]]

function conky_draw_pre()
    --Check that Conky has been running for at least 5s
    if conky_window == nil then
        return
    end

    local cs = cairo_xlib_surface_create(conky_window.display,
                                         conky_window.drawable,
                                         conky_window.visual,
                                         conky_window.width,
                                         conky_window.height)

    local cr = cairo_create(cs)

    -- The actual script goes here
    cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_source_rgba(cr, 1, 1, 1, .85)

    draw_date_time(cr)
    draw_info(cr)
    if progress_bar == 1 then draw_progress(cr) end

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
