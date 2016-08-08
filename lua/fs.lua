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
Table of file system path and label pairs. Adjoust accordingly.
]]
fs = {
    {"/", "ROOT"},
    {"/media/gabriele/DATA", "DATA"},
    {"/media/gabriele/KINGSTON", "KINGSTON"}
}

--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]



prefix = {"", "K", "M", "G", "T"}

fs_size = 0
fs_used = 0
fs_free = 0

cx, cy = 180, 128
offset_angle = 1/24

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_clock(cr)
    cairo_select_font_face(cr, "DJB Get Digital", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 36)
    cairo_set_source_rgba(cr, 0.4, .9, 0.4, 1)
    write_center_middle(cr, cx, cy - 20, conky_parse("${time %H:%M}"))

    cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, 10)
    write_center_middle(cr, cx, cy + 8, conky_parse("${time %A}"))
    cairo_set_font_size(cr, 16)
    write_center_middle(cr, cx, cy + 23, conky_parse("${time %d %b}"))
    cairo_set_font_size(cr, 10)
    write_center_middle(cr, cx, cy + 40, conky_parse("${time %Y}"))

    pat = cairo_pattern_create_radial (cx - 20, cy - 20, 25.6,
                                   102.4,  102.4, 128.0);
    cairo_pattern_add_color_stop_rgba (pat, 0, 1, 1, 1, .2);
    cairo_pattern_add_color_stop_rgba (pat, 1, 0, 0, 0, .2);
    cairo_set_source (cr, pat);
    cairo_arc (cr, cx, cy, 66, 0, 2 * math.pi);
    cairo_fill (cr);
    cairo_pattern_destroy (pat);
end

--------------------------------------------------------------------------------

function draw_middle(cr)

    -- Background disk
    cairo_set_source_rgba(cr, 1, 1, 1, .1)
    cairo_arc (cr, cx, cy, 54, 0, 2 * math.pi);
    cairo_fill (cr);

    -- Foreground fill
    h = fs_used / fs_size

    -- TODO: Change color according to fill %
    cairo_set_source_rgba(cr, 1, 1, 1, .9)

    cairo_save(cr)
    rotate(cr, -1/4)

    a = math.acos( 1 - h * 2 )
    cairo_arc(cr, cx, cy, 54, -a, a)
    cairo_fill(cr)

    cairo_restore(cr)

    local i = 2
    local free = fs_free


    while free > 1023 do
        free = free / 1024
        i = i + 1
    end
    text = math.floor(free + .5) .. " " .. prefix[i] .. "B"

    cairo_set_font_size(cr, 14)
    if h <= .5 then -- write in the shaded area
        d, s = (h - 1) * 54 + 8, (h - 1) * 54 - 8
    else -- write in the full area
        cairo_set_source_rgba(cr, .2, .2, .2, 1)
        d, s = h * 54 - 8, 8 + h * 54
    end
    write_center_middle(cr, cx, cy + 54 * (1-2*h) + d, text)
    write_center_middle(cr, cx, cy + 54 * (1-2*h) + s, "Free")
end

--------------------------------------------------------------------------------

function draw_file_systems(cr)
    fs_size = 0
    fs_used = 0
    fs_free = 0
    for entry = 1, #fs do
        perc = conky_parse("${fs_used_perc " .. fs[entry][1]  .. "}")
        cairo_set_source_rgba(cr, 1, 1, 1, 1)

        -- File system ring
        local angle = (entry - 1) / #fs + offset_angle

        cairo_save(cr)
        rotate(cr, angle)
        cairo_set_source_rgba(cr, 1, 1, 1, 0.2)
        draw_arc(cr, cx, cy, 78, 4, -1 / #fs * 100 / 106, 0) -- 106 creates the gap
        cairo_set_source_rgba(cr, 1, 1, 1, 1)
        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end
        draw_arc(cr, cx, cy, 78, 4, -perc / #fs / 106, 0)
        cairo_set_line_width(cr, 1.5)
        draw_segment(cr, cx + 70, cy, cx + 70 + 30, cy)

        cairo_restore(cr)

        -- Horizontal line
        cairo_set_line_width(cr, 1.5)
        if tonumber(perc) > 95 then
            cairo_set_source_rgba(cr, 1, 0.1, 0.1, 1)
        elseif tonumber(perc) > 85 then
            cairo_set_source_rgba(cr, 0.85, 0.4, 0.05, 1)
        end
        if math.cos(2 * math.pi * angle) < 0 then d = -80 else d = 80 end
        draw_segment(cr, cx + 100 * math.cos(-2 * math.pi * angle),
                         cy + 100 * math.sin(-2 * math.pi * angle),
                         cx + 100 * math.cos(-2 * math.pi * angle) + d,
                         cy + 100 * math.sin(-2 * math.pi * angle))

        -- Status Bullet
        unmounted = conky_parse("${fs_type " .. fs[entry][1]  .. "}") == "unknown"
        if unmounted then
            cairo_set_source_rgba(cr, 0.3, .3, 0.3, 1)
        else
            cairo_set_source_rgba(cr, 0, .75, 0, 1)
            -- Increment free and total memory
            fs_data = string.split( conky_parse("${exec bash -c 'read a b c d e _ < <(df -P " .. fs[entry][1]  .. " | tail -1); echo $b $c $d'}"), ' ')
            fs_size = fs_size + tonumber( fs_data[1] )
            fs_used = fs_used + tonumber( fs_data[2] )
            fs_free = fs_free + tonumber( fs_data[3] )
        end
        if math.cos(2 * math.pi * angle) < 0 then d = -74 else d = 74 end
        if math.sin(2 * math.pi * angle) < 0 then s = 8 else s = -8 end
        cairo_arc(cr, cx + 100 * math.cos(-2 * math.pi * angle) + d,
                      cy + 100 * math.sin(-2 * math.pi * angle) + s,
                      4, 0, 2 * math.pi)
        cairo_fill(cr)

        -- File System label
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

        if math.cos(2 * math.pi * angle) < 0 then d = -66 else d = 66 end
        if math.sin(2 * math.pi * angle) < 0 then s = 4 else s = -4 end
        cairo_set_font_size(cr, 10)
        writer(cr, cx + 100 * math.cos(-2 * math.pi * angle) + d,
                   cy + 100 * math.sin(-2 * math.pi * angle) + s,
                   fs[entry][2])

        -- Write the rest of the details
        cairo_select_font_face(cr, "Neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 8)
        if math.cos(2 * math.pi * angle) < 0 then d = -80 else d = 80 end
        if unmounted then text = "not mounted" else text = perc .. "%" end
        writer_perc(cr, cx + 100 * math.cos(-2 * math.pi * angle) + d,
                        cy + 100 * math.sin(-2 * math.pi * angle) - s,
                        text)
        if not unmounted then
            writer_free(cr, cx + 100 * math.cos(-2 * math.pi * angle),
                            cy + 100 * math.sin(-2 * math.pi * angle) - s,
                            conky_parse("${fs_free " .. fs[entry][1]  .. "}"))
        end
    end

    -- Main ring shadow
    cairo_set_source_rgba(cr, 0.2, 0.2, 0.2, .2)
    draw_arc(cr, cx, cy, 64, 14, 0, 1)

    -- Main ring
    cairo_set_source_rgba(cr, 1, 1, 1, 1)
    draw_arc(cr, cx, cy, 64, 8, 0, 1)

end

--------------------------------------------------------------------------------
-- Main function starts here
--------------------------------------------------------------------------------

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

    local updates = conky_parse('${updates}')
    update_num = tonumber(updates)

    -- The actual script goes here

    -- draw_clock(cr)
    draw_file_systems(cr)
    draw_middle(cr)

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
