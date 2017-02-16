--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]

newoption {
    trigger = "allow-shell",
    description = "Allows the usage of shell commands without confirmation"
}

newoption {
    trigger = "allow-install",
    description = "Allows the usage of install scripts without confirmation"
}

newoption {
    trigger = "ignore-updates",
    description = "Allows the usage of zpm without dependency update checks"
}

newoption {
    trigger = "allow-module",
    description = "Allows the updating and installing of modules without confirmation"
}

newoption {
    trigger = "profile",
    description = "Profiles the given commands"
}

newoption {
    trigger = "update",
    description = "Updates the dependencies to the newest version given the constraints"
}

newaction {
    trigger = "profile",
    description = "Profiles the given commands",
    onEnd = function()
        ProFi:stop()
        ProFi:writeReport(path.join(_MAIN_SCRIPT_DIR, "profile.txt"))
    end
}

newaction {
    trigger = "self-update",
    description = "Updates the premake executable to the latest version",
    execute = function()

        zpm.install.updatePremake(false, true)

        premake.action.call("update-bootstrap")
        premake.action.call("update-registry")
        premake.action.call("update-zpm")
        premake.action.call("update-modules")

        zpm.install.createSymLinks()
    end
}

newaction {
    trigger = "show-cache",
    description = "Shows the location of the ZPM cache",
    execute = function()

        printf("ZPM cache location: %s\n", zpm.env.getCacheLocation());

    end
}

newaction {
    trigger = "show-install",
    description = "Shows the location of the ZPM install",
    execute = function()

        printf("ZPM install location: %s\n", zpm.install.getInstallDir());

    end
}