#!/bin/bash
#
# This file is part of "New Life" which is released under GPL.
# See file LICENCE or go to http://www.gnu.org/licenses/ for full license
# details.
#
# New Life is a series of custom scripts for Conky, a system monitor, based on
# torsmo.
#
# Copyright (c) 2016 Gabriele N. Tornetta <phoenix1987@gmail.com>. All rights
# reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

cd "$(dirname "$0")" ;
python python/wu.py -d ;
conky -c scripts/cpu ;
conky -c scripts/info ;
conky -c scripts/mem ;
conky -c scripts/fs ;
conky -c scripts/net ;
conky -c scripts/wu
