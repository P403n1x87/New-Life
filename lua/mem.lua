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
Table of memory type and label pairs. Adjoust accordingly.
]]
mem = {
    {"mem", "RAM"},
    {"swap", "SWAP"}
}

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]

-- Geometry
cx, cy = 180, 80
offset_angle = 1/10
r = 54  -- Main ring radius. This controls the overall size
t = 8   -- Main ring thickness

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_dial(cr)
    local R = r - t / 2

    cairo_select_font_face(cr, "DJB Get Digital", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 18)
    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    write_center_middle(cr, cx, cy - 16, "R:" .. conky_parse("$memmax}"))
    write_center_middle(cr, cx, cy + 16, "S:" .. conky_parse("$swapmax}"))

    pat = cairo_pattern_create_radial (cx - 20, cy - 20, 25.6,
                                   102.4,  102.4, 128.0);
    cairo_pattern_add_color_stop_rgba (pat, 0, 1, 1, 1, .2);
    cairo_pattern_add_color_stop_rgba (pat, 1, 0, 0, 0, .2);
    cairo_set_source (cr, pat);
    cairo_arc (cr, cx, cy, R, 0, 2 * math.pi);
    cairo_fill (cr);
    cairo_pattern_destroy (pat);
end

--------------------------------------------------------------------------------

function draw_memory(cr)
    local R = r + 14    -- Indicator arc radius
    local l = 32        -- Radial line length
    local L = 80        -- Horizontal line length

    for entry = 1, #mem do
        perc = conky_parse("${" .. mem[entry][1] .. "perc}")
        cairo_set_source_rgba(cr, 1, 1, 1, 1)

        -- File system ring
        local angle = (entry - 1) / #mem + offset_angle

        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end

        cairo_save(cr)
        rotate(cr, angle)
        cairo_set_source_rgba(cr, 1, 1, 1, 0.2)
        draw_arc(cr, cx, cy, R, 4, -1 / #mem * 100 / 106, 0) -- 106 creates gap
        cairo_set_source_rgba(cr, 1, 1, 1, 1)
        draw_arc(cr, cx, cy, R, 4, -perc / #mem / 106, 0)

        cairo_set_line_width(cr, 1.5)
        draw_segment(cr, cx + r, cy, cx + r + l, cy)

        cairo_restore(cr)

        -- Horizontal line
        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end
        cairo_set_line_width(cr, 1.5)
        if math.cos(2 * math.pi * angle) < 0 then d = -1 else d = 1 end
        local J = r + l
        draw_segment(cr, cx + J * math.cos(-2 * math.pi * angle),
                         cy + J * math.sin(-2 * math.pi * angle),
                         cx + J * math.cos(-2 * math.pi * angle) + d * L,
                         cy + J * math.sin(-2 * math.pi * angle))

        -- Memory label
        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
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

        if math.cos(2 * math.pi * angle) < 0 then d = -1 else d = 1 end
        if math.sin(2 * math.pi * angle) < 0 then s = 4 else s = -4 end
        cairo_set_font_size(cr, 10)
        writer(cr, cx + J * math.cos(-2 * math.pi * angle) + d * L,
                   cy + J * math.sin(-2 * math.pi * angle) + s,
                   mem[entry][2])

        -- Write the rest of the details
        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 8)
        if math.cos(2 * math.pi * angle) < 0 then d = -1 else d = 1 end
        writer_perc(cr, cx + J * math.cos(-2 * math.pi * angle) + d * L,
                        cy + J * math.sin(-2 * math.pi * angle) - s,
                        perc .. "%")

        writer_free(cr, cx + J * math.cos(-2 * math.pi * angle),
                        cy + J * math.sin(-2 * math.pi * angle) - s,
                        conky_parse("${" .. mem[entry][1] .. "free}"))
    end

    -- Main ring shadow
    cairo_set_source_rgba(cr, 0.4, 0.4, 0.4, .1)
    draw_arc(cr, cx, cy, r, 2 * t, 0, 1)

    -- Main ring
    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    draw_arc(cr, cx, cy, r, t, 0, 1)

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
    draw_dial(cr)
    draw_memory(cr)

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
