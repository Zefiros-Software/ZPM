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


-- Git
zpm.git = {}

zpm.git.lfs = {}

function zpm.git.share( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    --os.execute( "git config core.sharedRepository 0777" ) 
    
    os.chdir( current )
end

function zpm.git.checkout( destination, version )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    local status, errorCode = os.outputof( "git status" )
    
    if status:contains(version) == false then
        printf( "Checkingout version %s", version )
        os.execute( "git checkout -q -f -B " .. version ) 
    end

    os.chdir( current )

end

function zpm.git.pull( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    if url ~= nil then        
        os.execute( "git remote set-url origin " .. url  )
    end
    
    os.execute( "git checkout -q master" )
    os.execute( "git pull" )
    os.execute( "git fetch --tags -q --recurse-submodules -j 8" )
    os.execute( "git submodule update --init --recursive -j 8" )
    
    os.chdir( current )
    
end

function zpm.git.clone( destination, url )
    
    os.execute( string.format( "git clone -v --recurse -j8 --progress \"%s\" \"%s\"", url, destination ) )
    zpm.git.share( destination )
    
end

function zpm.git.getTags( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    local tagStr, errorCode = os.outputof( "git tag" )
    local tags = {}
    
    for _, s in ipairs( tagStr:explode( "\n" ) ) do
    
        if s:len() > 0 then
        
            local version = s:match( "[.-]*([%d+%.]+.*)" )
            if pcall( zpm.semver, version ) then
                table.insert( tags, {
                    version = version,
                    tag = s
                } )
            end
        end
	end   
    
    
    table.sort( tags, function( t1, t2 )         
        return bootstrap.semver( t1.version ) > bootstrap.semver( t2.version )
    end )
    
    os.chdir( current )  
      
    return tags
end

function zpm.git.archive( destination, output, tag )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    os.execute( "git archive --format=zip --output=" .. output .. " " .. tag )
    
    os.chdir( current )
end

function zpm.git.cloneOrPull( destination, url )

    if os.isdir( destination ) then
        zpm.git.pull( destination, url )
    
    else
        zpm.git.clone( destination, url )
    end
end


function zpm.git.lfs.checkout( destination, checkout )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    os.execute( "git checkout -q -f -B " .. checkout )
    os.execute( "git lfs checkout" )
    os.execute( "git submodule update --init --recursive -j 8" )
    
    os.chdir( current )

end

function zpm.git.lfs.pull( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    if url ~= nil then        
        os.execute( "git remote set-url origin " .. url  )
    end
    
    os.execute( "git checkout -q master" )
    os.execute( "git pull" )
    os.execute( "git lfs pull" )
    os.execute( "git fetch --tags -q --recurse-submodules -j 8" )
    os.execute( "git submodule update --init --recursive -j 8" )
    
    os.chdir( current )
    
end

function zpm.git.lfs.clone( destination, url )
    
    os.execute( string.format( "git lfs clone \"%s\" \"%s\"", url, destination ) )
    zpm.git.share( destination )
    
end

function zpm.git.lfs.cloneOrPull( destination, url )

    if os.isdir( destination ) then
        zpm.git.lfs.pull( destination, url )
    
    else
        zpm.git.lfs.clone( destination, url )
    end
end