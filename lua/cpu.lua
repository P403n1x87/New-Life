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
Number of cores to display.

To determine the number of cores available on you system use, e.g.

    cat /proc/cpuinfo | grep MHz

and count the number of lines.
]]
cores = 4

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]

cx, cy = 180, 128
offset_angle = 1/19

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_middle(cr)

    -- Background disk
    cairo_set_source_rgba(cr, 1, 1, 1, .1)
    cairo_arc (cr, cx, cy, 54, 0, 2 * math.pi);
    cairo_fill (cr);

    -- Foreground fill
    perc = tonumber( conky_parse( "${cpu cpu0}" ) )
    h = tonumber( conky_parse( "${cpu cpu0}" ) ) / 100

    -- TODO: Change color according to fill %
    cairo_set_source_rgba(cr, 1, 1, 1, .9)

    cairo_save(cr)
    rotate(cr, -1/4)

    a = math.acos( 1 - h * 2 )
    cairo_arc(cr, cx, cy, 54, -a, a)
    cairo_fill(cr)

    cairo_restore(cr)

    cairo_set_font_size(cr, 18)
    if h <= .5 then -- write in the shaded area
        d, s = (h - 1) * 54 + 8, (h - 1) * 54 - 8
    else -- write in the full area
        cairo_set_source_rgba(cr, .2, .2, .2, 1)
        d, s = h * 54 - 8, 8 + h * 54
    end
    write_center_middle(cr, cx, cy + 54 * (1-2*h) + d, perc .. "%")
end

--------------------------------------------------------------------------------

function draw_cpu(cr)
    for entry = 1, cores do
        perc = conky_parse("${cpu cpu" .. entry .. "}")
        cairo_set_source_rgba(cr, 1, 1, 1, 1)

        -- File system ring
        local angle = (entry - 1) / cores + offset_angle

        cairo_save(cr)
        rotate(cr, angle)
        cairo_set_source_rgba(cr, 1, 1, 1, 0.2)
        draw_arc(cr, cx, cy, 78, 4, -1 / cores * 100 / 106, 0) -- 106 creates the gap
        cairo_set_source_rgba(cr, 1, 1, 1, 1)
        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end
        draw_arc(cr, cx, cy, 78, 4, -perc / cores / 106, 0)

        cairo_set_line_width(cr, 1.5)
        draw_segment(cr, cx + 70, cy, cx + 70 + 30, cy)

        cairo_restore(cr)

        -- Horizontal line
        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end
        cairo_set_line_width(cr, 1.5)
        if math.cos(2 * math.pi * angle) < 0 then d = -80 else d = 80 end
        draw_segment(cr, cx + 100 * math.cos(-2 * math.pi * angle),
                         cy + 100 * math.sin(-2 * math.pi * angle),
                         cx + 100 * math.cos(-2 * math.pi * angle) + d,
                         cy + 100 * math.sin(-2 * math.pi * angle))
        -- Cpu label
        cairo_set_source_rgba(cr, 1, 1, 1, 1)
        if math.cos(2 * math.pi * angle) > 0 then -- Select RIGHT
            if math.sin(2 * math.pi * angle) < 0 then -- Select BOTTOM
                writer = write_bottom_right
                writer_perc = write_top_right
                writer_free = write_top_left
            else -- Select TOP
                writer = write_top_right
                writer_perc = write_bottom_right
                writer_free = write_bottom_left
            end
        else  -- Select LEFT
            if math.sin(2 * math.pi * angle) < 0 then -- Select BOTTOM
                writer = write_bottom_left
                writer_perc = write_top_left
                writer_free = write_top_right
            else -- Select TOP
                writer = write_top_left
                writer_perc = write_bottom_left
                writer_free = write_bottom_right
            end
        end

        if math.cos(2 * math.pi * angle) < 0 then d = -80 else d = 80 end
        if math.sin(2 * math.pi * angle) < 0 then s = 4 else s = -4 end
        cairo_set_font_size(cr, 12)
        writer(cr, cx + 100 * math.cos(-2 * math.pi * angle) + d,
                   cy + 100 * math.sin(-2 * math.pi * angle) + s,
                   "CORE " .. entry)

        -- Write the rest of the details
        cairo_set_font_size(cr, 8)
        if math.cos(2 * math.pi * angle) < 0 then d = -80 else d = 80 end
        writer_perc(cr, cx + 100 * math.cos(-2 * math.pi * angle) + d,
                        cy + 100 * math.sin(-2 * math.pi * angle) - s,
                        perc .. "%")
    end

    -- Main ring shadow
    cairo_set_source_rgba(cr, 0.2, 0.2, 0.2, .1)
    draw_arc(cr, cx, cy, 64, 14, 0, 1)

    -- Main ring
    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    draw_arc(cr, cx, cy, 64, 8, 0, 1)

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

    local updates = tonumber(conky_parse('${updates}'))
    if updates > 3 then -- We are using the CPU now so this is needed
        -- The actual script goes here
        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
        draw_middle(cr)
        draw_cpu(cr)
    end

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
