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

-- Common procedures

function rotate(cr, rangle)
    cairo_translate(cr, cx, cy)
    cairo_rotate(cr, -2 * math.pi * rangle)
    cairo_translate(cr, -cx, -cy)
end

function draw_arc(cr, x, y, r, w, s, e) -- r: radius | w: width | s: start | e: end
    cairo_set_line_width(cr, w)
    cairo_arc(cr, x, y, r, 2 * s * math.pi, 2 * math.pi * e )
    cairo_stroke(cr)
end

function draw_segment(cr, sx, sy, ex, ey)
    cairo_move_to(cr, sx, sy)
    cairo_line_to(cr, ex, ey)
    cairo_stroke(cr)
end

function _writer(cr, x, y, text)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
    cairo_stroke(cr)
end

function write_top_right(cr, x, y, text)
    extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    _writer(cr, x - extents.width, y, text)
end

function write_top_left(cr, x, y, text)
    _writer(cr, x, y, text)
end

function write_bottom_right(cr, x, y, text)
    extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    _writer(cr, x - extents.width, y + extents.height, text)
end

function write_bottom_left(cr, x, y, text)
    extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    _writer(cr, x, y + extents.height, text)
end

function write_center_middle(cr, x, y, text)
    extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    _writer(cr, x - extents.width/2, y + extents.height/2, text)
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
