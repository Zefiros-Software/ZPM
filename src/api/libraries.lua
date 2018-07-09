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

zpm.api.libraries = {
    export = {},
    global = {}
}

function zpm.api.libraries.default(env, package)

    for name, func in pairs(premake.field._list) do
        if not env[name] then

            if name:contains("command") then

                env[name] = function(command)
                    _G[name](command)                    
                end
            else

                if func.kind == "list:directory" or func.kind == "list:file" then

                    env[name] = function(...)

                        local args = ...
                        if type(args) ~= "table" then
                            args = { args }
                        end

                        for i, dir in ipairs(args) do
                            args[i] = path.join(package.abslocation, dir)
                        end

                        _G[name](args)
                    end

                    if _G["remove" .. name] ~= nil then
                        env["remove" .. name] = function(...)

                            local args = ...
                            if type(args) ~= "table" then
                                args = { args }
                            end

                            for i, dir in ipairs(args) do
                                args[i] = path.join(package.abslocation, dir)
                            end

                            _G["remove" .. name](args)
                        end
                    end

                else
                    env[name] = function(...)          
                        _G[name](...)
                    end

                    if _G["remove" .. name] ~= nil then
                        env["remove" .. name] = function(...)
                            _G["remove" .. name](...)
                        end
                    end
                end
            end
        end
    end
end

function zpm.api.libraries.global.project(package)

    return function(name)
        local version = iif(package.version == nil, package.tag, package.version)
        local alias = string.format("%s-%s-%s", name, version, string.sha1(package.name):sub(0,5))
        project(alias)
        filename(name)
        zpm.util.setTable(package, {"aliases", name}, alias)

        if package.hash ~= "LOCAL" then
            location(path.join(package.abslocation, ".zpm" ))
        else
            location(package.abslocation)
        end
        targetdir(package.bindir)
        objdir(package.objdir)      
        targetname(name)
    
        warnings "Off"
        

        -- make sure we can actually 'compile' header only libraries
        -- (lame I know)
        if not os.isdir(path.join(package.abslocation, ".zpm")) then
            os.mkdir(path.join(package.abslocation, ".zpm"))
        end
        local ignore = path.join(package.abslocation, ".zpm/.gitignore")
        if not os.isfile(ignore) then
            os.writefile_ifnotequal("*", ignore)
        end
        local dummyFile = path.join(package.abslocation, ".zpm/dummy.cpp")
        os.writefile_ifnotequal(("void Dummy%s(){  return; }"):format(string.sha1(dummyFile)), dummyFile)
        files(dummyFile)
    end
end

function zpm.api.libraries.global.links(package)
    
    return function(libraries)
        local fltr = table.deepcopy(zpm.meta.filter)
        local found = true
        if type(libraries) ~= "table" then
            libraries = {libraries}
        end

        for _, library in ipairs(libraries) do
            zpm.util.setTable(zpm.loader.project.builder.cursor, {"projects", zpm.meta.project, "links", library}, fltr)
        end

    end
end

function zpm.api.libraries.global.linksfiles(package)
    
    return function(libraries)
        local fltr = table.deepcopy(zpm.meta.filter)
        local found = true
        if type(libraries) ~= "table" then
            libraries = {libraries}
        end

        for i, file in ipairs(libraries) do
            libraries[i] = path.join(package.abslocation, file)
        end

        links(libraries)
    end
end

function zpm.api.libraries.global.filter(package)

    return filter
end


function zpm.api.libraries.global.group(package)

    return group
end

function zpm.api.libraries.export.uses(package)

    return zpm.uses
end

function zpm.api.libraries.export.has(package)

    return zpm.has
end

function zpm.api.libraries.export.setting(package)

    return zpm.setting
end

function zpm.api.libraries.export.configuration(package)

    return zpm.configuration
end

function zpm.api.libraries.export.export(package)

    return zpm.export
end

function zpm.api.libraries.export.repository(package)

    return function()
        return package.package:getRepository()
    end
end

function zpm.api.libraries.export.definition(package)

    return function()
        return package.package:getDefinition()
    end
end

function zpm.api.libraries.export.exportpath(package)

    return function()
        return package.abslocation
    end
end