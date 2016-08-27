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

-- Number of forecast days to display
days = 4

-- Number of forcast hours from current time to display
hours = 6

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]

w = 310 --conky_window.width
h = 320

wu_paths = "current_observation.display_location.full " ..
           "current_observation.observation_time " ..
           "current_observation.weather " ..
           "current_observation.temp_c " ..
           "current_observation.relative_humidity " ..
           "current_observation.wind_kph " ..
           "current_observation.pressure_mb " ..
           "current_observation.icon " ..
           "hourly_forecast " ..
           "forecast.simpleforecast.forecastday"

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
    nt_rain         = "",
    cloudy          = ""
} -- see http://unitid.nl/iconfonts/?font=weathericons&size=big for more

data = nil

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function retrieve_data(paths)
    return conky_parse( "${exec python python/wu.py " .. paths .. "}" )
end

function draw_hourly(cr)
    local y = 160
    local hrs = math.min(hours, data[9])
    local d = w / hrs
    local paths_postfix = {".FCTTIME.hour ",
                           ".FCTTIME.min ",
                           ".temp.metric ",
                           ".icon ",
                           ".pop "}

    wu_hourly = ""
    for i = 1, hrs do
        for j = 1, #paths_postfix do
            wu_hourly = wu_hourly .. "hourly_forecast" .. i .. paths_postfix[j]
        end
    end
    hdata = string.split(retrieve_data(wu_hourly), "|")
    for i = 1, hrs do
        x = d * (i - 0.5)
        k = 5 * (i-1)

        cairo_set_source_rgba(cr, 1, 1, 1, .67)
        cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 8)
        write_center_middle(cr, x, y, hdata[k + 1] .. ":" .. hdata[k + 2])

        local s = 19
        write_top_left(cr, x - s, y + 54, "P")
        write_top_left(cr, x - s, y + 64, "T")

        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        write_top_right(cr, x + s, y + 54, hdata[k+5].."%")
        write_top_right(cr, x + s, y + 64, hdata[k+3].."°C")

        if tonumber(hdata[k+5]) > 95 then
            cairo_set_source_rgba(cr, 1, 0.4, 0.4, .67)
        elseif tonumber(hdata[k+5]) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.6, 0.25, .67)
        end
        cairo_select_font_face(cr, "Weather Icons", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 24)
        write_center_middle(cr, x, y + 20, icon_lookup[hdata[k + 4]])
    end
end

--------------------------------------------------------------------------------

function draw_days(cr)
    local y = 240
    local days = math.min(days + 1, data[10]) - 1
    local d = w / days
    local paths_postfix = {".date.weekday_short ",
                           ".high.celsius ",
                           ".low.celsius ",
                           ".icon "}

    wu_hourly = ""
    for i = 1, days do
        for j = 1, #paths_postfix do
            wu_hourly = wu_hourly .. "forecast.simpleforecast.forecastday" .. i+1 .. paths_postfix[j]
        end
    end

    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    hdata = string.split(retrieve_data(wu_hourly), "|")
    for i = 1, days do
        x = d * (i - 0.5)
        k = 4 * (i-1)

        cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 14)
        write_center_middle(cr, x, y, hdata[k + 1])

        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 10)
        write_top_right(cr, x - 4, y + 64, hdata[k+3].."°C")
        write_top_left(cr, x + 4, y + 64, hdata[k+2].."°C")


        cairo_select_font_face(cr, "Weather Icons", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 28)
        write_center_middle(cr, x, y+24, icon_lookup[hdata[k + 4]])
    end
end


--------------------------------------------------------------------------------

function draw_current_cond(cr)
    local ix, iy = 56, 56
    local iw, ih = 112, 140
    local rx = ix + iw / 2 + 192
    local lx = ix + iw / 2 + 24

    if icon_lookup[data[8]] == nil then
        write_center_middle(cr, ix, iy, data[8])
    else
        -- The icons
        cairo_select_font_face(cr, "Weather Icons", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

        -- Current condition icon
        cairo_set_font_size(cr, 76)
        write_center_middle(cr, ix, iy, icon_lookup[data[8]])
        --write_center_middle(cr, ix, iy, "")

        -- Thermometer icon
        cairo_set_font_size(cr, 32)
        write_bottom_left(cr, lx, 30, "")
    end

    -- The text
    cairo_select_font_face(cr, "Michroma", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Location
    cairo_set_font_size(cr, 14)
    write_bottom_right(cr, rx, 0, data[1])

    -- Current temperature
    cairo_set_font_size(cr, 36)
    write_bottom_right(cr, rx, 30, math.floor(tonumber(data[4]) + .5) .. "˚C")

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
    cairo_set_source_rgba(cr, 1, 1, 1, 1)

    -- temp = conky_parse( "${exec python " .. script_path() .. "../python/wu.py " .. wu_paths .. "}" )
    temp = retrieve_data(wu_paths)
    --temp = conky_parse( "${exec python python/wu.py " .. wu_paths .. "}" )
    data = string.split(temp, "|")

    draw_current_cond(cr)
    draw_hourly(cr)
    draw_days(cr)

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
