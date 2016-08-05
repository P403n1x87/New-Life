#!/usr/bin/python
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
# Wundergroun API documented at
# -- https://www.wunderground.com/weather/api/d/docs?d=data/index&MR=1
#

import urllib2
import json
import sys

#
# BEGIN Configuration Section
#

# One of your currently active Wunderground API to perform requests with
wu_api_key  = ""

# Country of the location forecast are to be requested for
country     = "UK"

# City/Town the forecast are to be requested for
city        = "Glasgow"

# Features to be included in the json file, e.g.
# features    = ["conditions", "forecast10day", "astronomy", "hourly", "satellite"]
features    = ["conditions", "forecast10day", "astronomy"]

#
# END Configuration Section
#

class Bunch():
    '''
    Custom Bunch class. Lists are converted into single dictionary entries
    named as key + id (e.g. forecastday1). The dictionary entry associated to
    the original key holds the number of list entries (e.g. wu_data.forecastday
    will contain 10)
    '''

    def __init__(self, o = None):
        if o.__class__ == {}.__class__:
            self.__dict__ = o
            for key in self.__dict__.keys():
                if self.__dict__[key].__class__ == {}.__class__:
                    self.__dict__[key] = Bunch(self.__dict__[key])

                elif self.__dict__[key].__class__ == [].__class__:
                    l = self.__dict__[key]
                    self.__dict__[key] = len(self.__dict__[key])
                    i = 1
                    for e in l:
                        self.__dict__["%s%d" % (key, i)] = Bunch(e) if e.__class__ == {}.__class__ else e

    def __getattr__(self, name):
        return getattr(self.__dict__, name, None)

    def path(self, p):
        a = p.split('.')
        r = self.__dict__
        for e in a:
            r = r[e]
        return r

def generate_wu_url():
    return 'http://api.wunderground.com/api/%s/%s/q/%s/%s.json' % (wu_api_key, "/".join(features), country.replace(" ", "%20"), city.replace(" ", "%20"))

def download_json():
    try:
        f = urllib2.urlopen( generate_wu_url() )
        json_string = f.read()

    except:
        print "ERROR|CANNOT DOWNLOAD"

    finally:
        f.close()

    with open("/tmp/wu.json", "w") as f:
        f.write(json_string)

def load_local_json():
    try:
        with open("/tmp/wu.json", "r") as f:
            return Bunch( json.loads( f.read() ) )

    except:
        print "ERROR|NO LOCAL JSON"


def usage():
    print "Wunderground Python utility script for the New Life set of Conky scripts."
    print ""
    print "Copyright (C) 2016 Gabriele N. Tornetta <phoenix1987@gmail.com>."
    print "All rights reserved."
    print ""
    print "This application is distributed under the terms of the GPL."
    print ""
    print "USAGE:"
    print ""
    print "    python wu.py [-d] path1 path2 ..."
    print ""
    print "WHERE:"
    print ""
    print "    -d     forces wu.py to request a new json file from Wunderground,"
    print "           according to the information provided in the configuration"
    print "           section."
    print ""
    print "    pathN  A sequence of space separated paths through the dictionary"
    print "           generated from the json file (e.g. current_observation.temp_c"
    print "           for the temperature in Celsius)."
    print ""

################################################################################

if __name__ == "__main__":
    wu_data = load_local_json()
    i = 1

    if len(sys.argv) < 2:
        usage()

    if sys.argv[1] == "-d":
        download_json()
        i = 2

    try:
        r = []
        for p in sys.argv[i:]:
            e = str(wu_data.path(p))
            r.append( e if e else "n.d." )

        print '|'.join(r)

    except:
        print "ERROR|INVALID PATH '", p, "'"
