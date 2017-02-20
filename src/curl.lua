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

Curl = newclass "Curl"

function Curl:init(loader)
    self.loader = loader
    self.location = iif(os.is("windows"), self.loader.bin, "curl")

    self:_downloadCurl(self.location)
end

function Curl:_downloadCurl(destination)

    local destFile = path.join(destination, "curl.exe")
    if not os.is("windows") or os.isfile(destFile) then
        return nil
    end
    
    local setupFile = path.join(self.loader.temp, "curl.zip")

    if not os.isfile(setupFile) then
        os.executef( 'powershell -command "Invoke-WebRequest -Uri %s -OutFile %s  -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox"', self.loader.config("curl"), setupFile )
    end

    zip.extract(setupFile, self.loader.temp)

    zpm.assert(os.rename(path.join(self.loader.temp, "curl.exe"), destFile))
    zpm.assert(os.isfile(destFile), "Curl is not installed!")
end