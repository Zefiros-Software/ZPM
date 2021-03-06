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

Module = newclass("Module", Package)

function Module:init(loader, manifest, settings)

    self.super:init(loader, manifest, settings)
end

function Module:onLoad(version, tag)

    if self:isTrusted() then
        require(self.fullName, iif(version, version, tag))
    end
end

function Module:pullRepository()

    local selfM = Module:cast(self)
    selfM:_update(selfM:getDirectory(), selfM:getRepository())
end

function Module:getRepository()

    local selfM = Module:cast(self)
    return selfM:getHeadPath()
end

function Module:getDefinition()

    local selfM = Module:cast(self)
    return selfM:getHeadPath()
end

function Module:install()
    local selfM = Module:cast(self)

    local headPath = selfM:getHeadPath()
    local modPath = selfM:getDirectory()
    if not os.isdir(headPath) then
        noticef("- Installing module '%s'", selfM.fullName)
        selfM:_update(modPath, headPath)
    else
        noticef("- Module '%s' is already installed!", selfM.fullName)
    end
end

function Module:update()
    local selfM = Module:cast(self)

    local headPath = selfM:getHeadPath()
    local modPath = selfM:getDirectory()
    if os.isdir(headPath) then
        noticef("- Updating module '%s'", selfM.fullName)
        selfM:_update(modPath, headPath)
    else
        warningf("- Module '%s' is not installed!", selfM.fullName)
    end
end

function Module:uninstall()
    local selfM = Module:cast(self)

    local modPath = selfM:getDirectory()
    if os.isdir(modPath) then
        noticef("- Uninstalling module '%s'", selfM.fullName)
        zpm.util.rmdir(modPath)

        local vendorPath = selfM:getVendorDirectory()
        local matches = os.matchdirs(vendorPath)
        if #matches == 1 and matches[1] == vendorPath then
            zpm.util.rmdir(vendorPath)
        end
    end
end

function Module:isInstalled()
    local selfM = Module:cast(self)

    return os.isdir(selfM:getDirectory())
end

function Module:getDirectory()
    local selfM = Module:cast(self)

    return path.join(selfM.manifest.manager:getDirectory(), selfM.fullName)
end

function Module:getVendorDirectory()
    local selfM = Module:cast(self)

    return path.join(selfM.manifest.manager:getDirectory(), selfM.vendor)
end


function Module:getHeadPath()
    local selfM = Module:cast(self)
    
    return path.join(selfM:getDirectory(), "head")
end

function Module:_update(modPath, modPath)
    local selfM = Module:cast(self)

    local modPath = selfM:getDirectory()
    local headPath = path.join(modPath, "head")

    zpm.git.cloneOrPull(headPath, selfM.repository)

    local tags = zpm.git.getTags(headPath)
    for _, tag in ipairs(tags) do

        local verPath = path.join(modPath, tag.version)

        if not os.isdir(verPath) then

            noticef(" - Installing version '%s'", tag.version)
            
            assert(os.mkdir(verPath))
            zpm.git.export(headPath, verPath, tag.hash)
        end
    end
end