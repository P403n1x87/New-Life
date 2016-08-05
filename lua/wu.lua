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

--[[ Not implemented yet ]]
days = 2

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]

w = 360 --conky_window.width
h = 260

wu_paths = "current_observation.display_location.full " ..
           "current_observation.observation_time " ..
           "current_observation.weather " ..
           "current_observation.temp_c " ..
           "current_observation.relative_humidity " ..
           "current_observation.wind_kph " ..
           "current_observation.pressure_mb " ..
           "current_observation.icon"

icon_lookup = {
    chancerain      = "",
    nt_chancerain   = "",
    partlycloudy    = "",
    nt_partlycloudy = "",
    clear           = "",
    nt_clear        = "",
    mostlycloudy    = "",
    nt_mostlycloudy = "",
    rain            = "",
    nt_rain         = ""
} -- see http://unitid.nl/iconfonts/?font=weathericons&size=big for more

data = nil

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_current_cond(cr)
    local ix, iy = 64, 74
    local iw, ih = 112, 112
    local rx = ix + iw / 2 + 172
    local lx = ix + iw / 2 + 16

    if icon_lookup[data[8]] == nil then
        write_center_middle(cr, ix, iy, data[8])
    else
        -- The icons
        cairo_select_font_face(cr, "Weather Icons", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

        -- Current condition icon
        cairo_set_font_size(cr, 82)
        write_center_middle(cr, ix, iy, icon_lookup[data[8]])
    end

    -- The text
    cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Location
    cairo_set_font_size(cr, 18)
    write_bottom_left(cr, 0, 0, data[1])

    -- Current temperature
    cairo_set_font_size(cr, 46)
    write_bottom_right(cr, rx, 36, math.floor(tonumber(data[4]) + .5) .. "˚C")

    -- Current condition text
    cairo_set_font_size(cr, 10)
    if data[3] == "n.d." then
        text = firstToUpper(data[8])
    else
        text = data[3]
    end
    write_center_middle(cr, ix, iy + ih / 2 + 16, text)

    cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 10)

    -- Humidity
    local a = 100

    write_bottom_right(cr, rx, a, data[5])
    write_bottom_right(cr, rx, a+15, math.floor(tonumber(data[6]) * 5 / 18 + .5) .. " m/s")
    write_bottom_right(cr, rx, a+2*18, data[7].. " mb")


    cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 8)
    write_bottom_left(cr, lx, a, "HUMIDITY")
    write_bottom_left(cr, lx, a+18, "WIND")
    write_bottom_left(cr, lx, a+2*18, "PRESSURE")

    write_top_left(cr, 0, h, data[2])
end

--------------------------------------------------------------------------------

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
    --cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_source_rgba(cr, 1, 1, 1, .85)

    -- temp = conky_parse( "${exec python " .. script_path() .. "../python/wu.py " .. wu_paths .. "}" )
    temp = conky_parse( "${exec python python/wu.py " .. wu_paths .. "}" )
    data = string.split(temp, "|")

    draw_current_cond(cr)

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
