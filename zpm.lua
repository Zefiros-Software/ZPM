--[[ @cond ___LICENSE___
-- Copyright (c) 2016 Koen Visscher, Paul Visscher and individual contributors.
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

-- Module initialisation
zpm = {}
zpm._VERSION = "1.0.1-beta"

-- Dependencies
zpm.JSON = (loadfile "json.lua")()
zpm.semver = require "semver"
zpm.bktree = require "bk-tree"
zpm.sandbox = require "sandbox"

zpm.cachevar = "ZPM_CACHE"

dofile( "config.lua" )
dofile( "printf.lua" )
dofile( "assert.lua" )
dofile( "util.lua" )

-- we need to do this before the rest
zpm.config.initialise()
    
dofile( "wget.lua" )
dofile( "git.lua" )
dofile( "registry.lua" )
dofile( "manifest.lua" )
dofile( "modules.lua" )
dofile( "assets.lua" )
dofile( "packages.lua" )
dofile( "build.lua" )
dofile( "github.lua" )
dofile( "install.lua" )

dofile( "commands/assets.lua" )
dofile( "commands/build.lua" )
    
premake.override(path, "normalize", function(base, p )

    if not zpm.util.hasGitUrl( p ) and not zpm.util.hasUrl( p ) then
        return base( p )
    end
    
    return p
end)

local builtWorkspaces = {}
    
zpm._workspaceCache = nil
premake.override(_G, "workspace", function(base, ... )

    local wkspc = base( ... )
    if select("#",...) > 0 then

        local name = select(1,...)
        zpm._workspaceCache = name
        
        if table.contains( builtWorkspaces, name ) then
            return wkspc
        end

        table.insert( builtWorkspaces, name )
        zpm.buildLibraries()
    end

    -- return to workspace
    base()

    return wkspc
end)
    
-- small hack so the first user defined project is the startup project
zpm._projectFirstCache = {}
premake.override(_G, "project", function( base, proj )    
    
    local val = base(proj)

    if proj ~= nil and zpm.build._isBuilding == false and zpm._workspaceCache ~= nil and zpm._projectFirstCache[zpm._workspaceCache] == nil then
        zpm._projectFirstCache[zpm._workspaceCache] = {}
        workspace()     
        startproject(proj)
        base(val.name)
    end

    return val
end)

function zpm.useProject( proj )

    if proj ~= nil and proj.projects ~= nil then

        for p, conf in pairs( proj.projects ) do

            local exporter = {}
            exporter[p] = conf.export

            if conf.uses ~= nil then
                for _, uses in ipairs( conf.uses ) do      
                   exporter[uses] = proj.projects[uses].export  
                end
            end    

            for uses, exp in pairs( exporter ) do     
                if exp ~= nil then                         

                    local curFlter = premake.configset.getFilter(premake.api.scope.current)
                    filter {}

                    if proj.projects[uses].kind == "StaticLib" then
                        links( uses )
                    end

                    exp()

                    premake.configset.setFilter(premake.api.scope.current, curFlter)
                end
            end

            if conf.packages ~= nil then
                for _, package in ipairs( conf.packages ) do
                    zpm.useProject( package )
                end
            end
        end                
    
    end
end

function zpm.uses( projects )

    if type( projects ) ~= "table" then
        projects = { projects }
    end
    
    for _, project in ipairs( projects ) do
        proj = zpm.build.findRootProject( project )
    
        zpm.useProject( proj )
    end
end

function zpm.buildLibraries()

    zpm.build._isBuilding = true

    local curFlter = premake.configset.getFilter(premake.api.scope.current)
    zpm.build._currentWorkspace = workspace().name

    filter {}
    group( string.format( "Extern/%s", zpm.build._currentWorkspace ) )    

    zpm.build.buildPackage( zpm.packages.root )
    
    group ""
    
    premake.configset.setFilter(premake.api.scope.current, curFlter)

    workspace()
    zpm.build._isBuilding = false
end


local function getCacheLocation()
	local folder = os.getenv(zpm.cachevar)
    
	if folder then
		return folder
    end
    
    if os.get() == "windows" then
        local temp = os.getenv("TEMP")
        zpm.assert( temp, "The temp directory could not be found!" )
        return path.join(temp, "zpm-cache")
    end
    
    return "/var/tmp/zpm-cache"
end


local function initialiseCacheFolder()

    -- cache the cache location
    zpm.cache = getCacheLocation()
    zpm.temp = path.join( zpm.cache, "temp" )
    
    if os.isdir( zpm.temp ) then
        os.rmdir( zpm.temp )
    end
    
    if not os.isdir( zpm.cache ) then
        zpm.assert( os.mkdir( zpm.cache ), "The cache directory could not be made!" )
    end
    
    --print( "Cache location:", zpm.cache )   
    
    if not os.isdir( zpm.temp ) then
        zpm.assert( os.mkdir( zpm.temp ), "The temp directory could not be made!" )
    end
    
    --print( "Temp location:", zpm.temp )  
    
end

function zpm.checkGit()

    local version, errorCode = os.outputof( "git --version" )
    zpm.assert(version:contains( "git version"), "Failed to detect git on PATH:\n %s", version )
    
    mversion = version:match( ".*(%d+%.%d+%.%d).*" )

    if premake.checkVersion( mversion, ">=2.9.0" ) == false then
        warningf( "Git version should be >=2.9.0, current is '%s'", mversion )
    end
end

initialiseCacheFolder()
zpm.modules.setSearchDir()

function zpm.onLoad()

    if _OPTIONS["profile"] then 
        ProFi = require( "mindreframer/ProFi", "@head" )
        ProFi:start()
    end

    zpm.checkGit()

    print( string.format( "Zefiros Package Manager '%s' - (c) Zefiros Software 2016", zpm._VERSION ) )
    
    zpm.wget.initialise()  
        
    if _ACTION ~= "install-zpm" and not _OPTIONS["version"] then      
        
        zpm.install.updatePremake( true )
    
        zpm.registry.load()
        zpm.manifest.load()        
        zpm.modules.load()
        
        if _ACTION ~= "self-update" and
           _ACTION ~= "show-cache" and
           _ACTION ~= "install-module" and
           _ACTION ~= "update-module" and
           _ACTION ~= "update-modules" then
            
            zpm.assets.load()
            zpm.packages.load()
            zpm.build.load()
        end
    end

    if _OPTIONS["profile"] then
        ProFi:stop()
        ProFi:writeReport( path.join( _MAIN_SCRIPT_DIR, "profile.txt" ) )
    end
end 

newoption {
    trigger     = "allow-shell",
    description = "Allows the usage of shell commands without confirmation"
}
newoption {
    trigger     = "allow-install",
    description = "Allows the usage of install scripts without confirmation"
}

newoption {
    trigger     = "ignore-updates",
    description = "Allows the usage of zpm without dependency update checks"
}

newoption {
    trigger     = "allow-module",
    description = "Allows the updating and installing of modules without confirmation"
}

newoption {
    trigger     = "profile",
    description = "Profiles the given commands"
}

newaction {
    trigger     = "self-update",
    description = "Updates the premake executable to the latest version",
    execute = function ()

        zpm.install.updatePremake( false, true )
                       
        premake.action.call( "update-bootstrap" )
        premake.action.call( "update-registry" )
        premake.action.call( "update-zpm" )
        premake.action.call( "update-modules" )
   
        zpm.install.createSymLinks()     
    end
}

newaction {
    trigger     = "show-cache",
    description = "Shows the location of the ZPM cache",
    execute = function ()
        
        printf( "ZPM cache location:" .. getCacheLocation() );
             
    end
}

if _ACTION == "self-update" or
   _ACTION == "show-cache" or
   _ACTION == "install-module" or
   _ACTION == "install-zpm" or
   _ACTION == "install-package" or
   _ACTION == "update-module" or
   _ACTION == "update-modules" or
   _ACTION == "update-bootstrap" or
   _ACTION == "update-registry" or
   _ACTION == "update-zpm" then
    -- disable main script
    _MAIN_SCRIPT = "."
        
end

newaction {
    trigger     = "install-zpm",
    description = "Installs zpm-premake in path",
    execute = function ()

        printf( zpm.colors.green .. zpm.colors.bright .. "Installing zpm-premake!" )
        
        if zpm.__isLoaded ~= true or zpm.__isLoaded == nil then
            zpm.onLoad()
            zpm.__isLoaded = true
        end

        zpm.install.initialise()
        zpm.install.setup()
        zpm.install.installInPath()
        zpm.install.setupSystem()
        
    end
}

newaction {
    trigger     = "install-package",
    description = "Installs all package dependencies",
    execute     = function()

        zpm.packages.install()

    end
}

return zpm