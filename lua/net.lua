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



--------------------------------------------------------------------------------
-- END of CONFIGURATION Section ------------------------------------------------
--------------------------------------------------------------------------------

--[[ Internal code

     Do not change unless you know what you're doing                          ]]


-- See https://searchcode.com/codesearch/view/13121006/

--------------------------------------------------------------------------------
-- Draw helpers ----------------------------------------------------------------
--------------------------------------------------------------------------------

function draw_wifi_quality(cr)
    -- TODO: Implement this function
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

    -- draw_wifi_quality(cr)

    -- Memory clean-up
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
