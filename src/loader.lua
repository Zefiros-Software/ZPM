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

Loader = newclass "Loader"

function Loader:init()

    self:_preInit()
    
    self.python = Python(self)

    self.config = Config(self.python)
    self.config:load()    

    self.cacheTime = self.config("cache.temp.cacheTime")

    self:fixMainScript()
    self:checkGitVersion()
    self:initialiseFolders()

    self.install = Installer(self)
    self.github = Github(self)
    self.http = Http(self)

    self.registries = Registries(self)
    self.registries.isRoot = true

    self.manifests = Manifests(self, self.registries)
end

function Loader:fixMainScript()

    if _ACTION == "self-update" or
        _ACTION == "show-cache" or
        _ACTION == "show-install" or
        _ACTION == "install-module" or
        _ACTION == "install-zpm" or
        _ACTION == "install-package" or
        _ACTION == "update-module" or
        _ACTION == "update-modules" or
        _ACTION == "update-bootstrap" or
        _ACTION == "update-registry" or
        _ACTION == "update-zpm" or
        _OPTIONS["version"] then
        -- disable main script
        _MAIN_SCRIPT = "."

    elseif os.isfile(path.join(_MAIN_SCRIPT_DIR, "zpm.lua")) then
        _MAIN_SCRIPT = path.join(_MAIN_SCRIPT_DIR, "zpm.lua")
    end
end

function Loader:checkGitVersion()

    local version, errorCode = os.outputof("git --version")
    zpm.assert(version:contains("git version"), "Failed to detect git on PATH:\n %s", version)

    mversion = version:match(".*(%d+%.%d+%.%d).*")

    if premake.checkVersion(mversion, ">=2.9.0") then
        self.gitCheckPassed = true
    else
        warningf("Git version should be >=2.9.0, current is '%s'", mversion)
    end
end

function Loader:initialiseFolders()
    
    local binDir = zpm.env.getBinDirectory()
    if not os.isdir(binDir) then
        zpm.assert(os.mkdir(binDir), "The bin directory '%s' could not be made!", binDir)
    end

    if os.isdir(self.temp) and self:_mayClean() then
         zpm.util.rmdir(self.temp)

        if os.isdir(self.temp) then
            warningf("Failed to clean temporary directory '%s'", self.temp)
        else
            zpm.assert(os.mkdir(self.temp), "The temp directory '%s' could not be made!", self.temp)
        end
    end    
end

function Loader:_preInit()

    self:_initialiseCache()

    if bootstrap then
        -- allow module loading in the correct directory
        bootstrap.directories = zpm.util.concat( { path.join(self.cache, "modules") }, bootstrap.directories)
    end    

    if zpm.cli.profile() then
        ProFi = require("mindreframer/ProFi", "@head")
        ProFi:setHookCount(0)
        ProFi:start()
    end
end

function Loader:_initialiseCache()

    self.cache = zpm.env.getCacheDirectory()

    if not os.isdir(self.cache) then
        zpm.assert(os.mkdir(self.cache), "The cache directory '%s' could not be made!", self.cache)
    end    
    
    self.temp = zpm.env.getTempDirectory()
    
    if not os.isdir(self.temp) then
        zpm.assert(os.mkdir(self.temp), "The temp directory '%s' could not be made!", self.temp)
    end
end

function Loader:_mayClean()

    if self.__cacheMayClean ~= nil then
        return self.__cacheMayClean
    end    

    self.__cacheMayClean = false
    local checkTime = self.config("cache.temp.checkTime")
    if not checkTime or os.difftime(os.time(), checkTime) > self.cacheTime then

        self.config:set("cache.temp.checkTime", os.time(), true)
        self.__cacheMayClean = true
    end

    return self.__cacheMayClean

end