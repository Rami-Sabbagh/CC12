--LIKO-12 DiskOS Edu Edition Downloader By RamiLego4Game

--CONFIG--
local GithubUsername = "RamiLego4Game" --Your GitHub username as it appears in the URL
local GithubReponame = "CC12" --The repo name as it appears in the URL
local FilterPreReleases = false --Avoid pre-releases.
local Title = "=---< LIKO-12 CraftOS Installer >---=" --The title of the installer (Shown in the top-bar)
local blacklist = {"/Installer.lua","/README.md","/LICENSE","/LICENSE-CraftOS"} --The files to not download
local DownloadAttempsCount = 10 --How many attemps to do before giving up when downloading a file ?
local DownloadAttempsDelay = 2  --The delay between each attemp in seconds.
----------

--The directory where the files will be stored while downloading.
local TempDir = "C:/.temp/Installer/"

--Not working--
--local _LIKO_Version = coroutine.yield("BIOS:GetVersion")
--if _LIKO_Version ~= "0.6.0.7_PRE" then color(8) print("DiskOS-Edu requires LIKO-12 V0.6.0.7_PRE !") return end

--Verify that the WEB peripheral is available.
if not WEB then
  color(8)
  print("The installer requires WEB peripheral and an internet connection.")
  return
end

color(8) print("\n\nWARNING !\n\nYou are about to replace your current operating system with a new one.\n\nAll of your data will be lost in the process !\n\nAre you still sure you want to continue ? (Y/N)\n\n\n",false) color(7)
local answer = string.lower(input() or ""); if answer ~= "y" then return end

--Require the JSON library
local json = require("Libraries/JSON")

--Get the screen resolution, the terminal size and the font size
local sw, sh = screenSize()
local tw, th = termSize()
local fw, fh = fontSize()

--Set the print cursor position
printCursor(0,th)

--Draws the progress bar, takes a value between 0 and 1, nil for no progress bar.
local function drawProgress(float)
  rect(0,sh-9, sw,9, false, 12) --Draw the bar
  
  if not float then return end --If no progress value then we are done.
  
  --The progress bar "=" chars
  local progChars = math.floor(float*32+0.5)
  local progStr = string.rep("=", progChars)..string.rep(" ", 32-progChars)
  
  --The % percentage.
  local precent = tostring(math.floor(float*100+0.5))
  precent = string.rep(" ",3-precent:len())..precent
  
  --Draw the text.
  color(1) print("["..progStr.."]"..precent.."%",1, sh-7)
end

--Draw the GUI
clear(5) --Clear the screen
rect(0,0, sw,9, false, 12) --The top bar
color(1) print(Title, 1,2, sw,"center") --Draw the title.
drawProgress() --Draw the bottom bar.

--Display a log message
local function display(text,col)
  --Push the text up
  screenshot(0,9+fh+2,sw,sh-9-fh-2-9):image():draw(0,9)
  --Clear the last line
  rect(0,sh-8-fh-3,sw,fh+2,false,5)
  --Display the new message
  color(col or 7) print(tostring(text),1,sh-9-fh-2)
  --Make sure that it's shown to the user
  flip()
end

--Display a crash message, but doesn't end the program.
local function crash(...)
  cprint("[CRASH]",...)
  
  printCursor(0,th+1) color(8)
  print(table.concat({...}," ")) flip()
end

--Display a red message
local function warn(...)
  cprint("[WARNING]",...)
  display(table.concat({...}," "), 8)
end

--Display a blue message
local function status(...)
  cprint("[STATUS]",...)
  display(table.concat({...}," "), 15)
end

--Display a light grey message
local function info(...)
  cprint("[INFO]",...)
  display(table.concat({...}," "), 7)
end

--Download a url.
local function download(url)
  
  --Send the web request
  local ticket = WEB.send(url,{
    headers = {
      ["User-Agent"] = "LIKO-12" --Github requires a User-Agent.
    }
  })
  
  local attemps = 1 --The current attemp number
  
  for event, id, url, data, errnum, errmsg, errline in pullEvent do
    if event == "webrequest" then
      if id == ticket then --This is our request !
        if not data then --Too bad !
          warn("Attemp #"..attemps.." Failed: ",errmsg)
          
          attemps = attemps + 1
          if attemps > DownloadAttempsCount then
            crash("Failed to download after "..attemps.." attemps: "..tostring(errmsg)) return
          end
          
          sleep(DownloadAttempsDelay) --The time between each attemp.
          
          ticket = WEB.send(url) --Attemp Again
        else --We got something !
          data.code = tonumber(data.code)
          if data.code >= 200 and data.code < 400 then
            return data.body --Success
          else
            crash("Bad response code: "..data.code) return -- :(
          end
        end
      end
    elseif event == "keypressed" then
      if id == "escape" then
        crash("Installation Terminated") return
      end
    end
  end
  
end

--Download a url, and decode it's body pretending it's JSON data.
local function downloadJSON(url)
  local data = download(url)
  if not data then return end
  
  local ok, t = pcall(json.decode,json,data)
  if not ok then
    crash("Failed to decode JSON: "..tostring(t))
    return
  end
  
  return t
end

--Check if the path is in the blacklist
function isBlackListed(path)
  for k, item in ipairs(blacklist) do
    if item == path then
      return true
    end
  end
  return false
end

--The downloading process--

status("Determining Latest Version")
local releases = downloadJSON("https://api.github.com/repos/"..GithubUsername.."/"..GithubReponame.."/releases") if not releases then return end
local latestReleaseTag = releases[1].tag_name
if FilterPreReleases then
  for k, v in ipairs(releases) do
    if not v.prerelease then
      latestReleaseTag = v.tag_name
      break
    end
  end
end
info("Latest Version:",latestReleaseTag)

status("Optaining Latest Version URL")
local refs = downloadJSON("https://api.github.com/repos/"..GithubUsername.."/"..GithubReponame.."/git/refs/tags/"..latestReleaseTag) if not refs then return end
local latestReleaseSha = refs.object.sha
info("SHA:", latestReleaseSha)

status("Downloading File Listing")
local tree = downloadJSON("https://api.github.com/repos/"..GithubUsername.."/"..GithubReponame.."/git/trees/"..latestReleaseSha.."?recursive=1")
if tree then tree = tree.tree else return end

local TotalFiles, TotalBytes = 0, 0
for k,v in ipairs(tree) do
  if not isBlackListed("/"..v.path) and v.size then
    TotalBytes = TotalBytes + v.size
    TotalFiles = TotalFiles + 1
  end
end
info("Total Files:",TotalFiles)

status("Downloading "..math.floor(TotalBytes/1024+0.5).."KB") drawProgress(0)
fs.newDirectory(TempDir) --Create the download temp folder

local DownloadedBytes, DownloadedFiles = 0, 0
function downloadBlob(v,k)
  if isBlackListed("/"..v.path) then return end
  if v.type == "tree" then --Folder
    cprint("[LOG]","New Directory: "..v.path)
    display("New Directory: "..v.path, 7)
    fs.newDirectory(TempDir..v.path)
  else --File
    cprint("[LOG]","File ("..(DownloadedFiles+1).."/"..TotalFiles.."): "..v.path)
    display("File ("..(DownloadedFiles+1).."/"..TotalFiles.."): "..v.path, 6)
    local data = download("https://raw.github.com/"..GithubUsername.."/"..GithubReponame.."/"..latestReleaseTag.."/"..(v.path):gsub(" ","%%20"))
    if not data then return true end
    fs.write(TempDir..v.path,data)
    DownloadedFiles = DownloadedFiles + 1
    DownloadedBytes = DownloadedBytes + v.size
  end
end

for k,v in ipairs(tree) do
  if downloadBlob(v,k) then return end
  drawProgress(DownloadedBytes/TotalBytes)
end

drawProgress()
status("Download completed, Installing...")
info("Entered the no going back stage !")

--The installing script

status("Formating the disk drives")

local function index(path, list)
  local path = path or "C:/"
  local list = list or {}
  
  local items = fs.directoryItems(path)
  for id, item in ipairs(items) do
    if fs.isDirectory(path..item) then
      index(path..item.."/", list)
      table.insert(list,path..item)
    else
      table.insert(list,path..item)
    end
  end
  
  return list
end

local toDelete = index("C:/"); index("D:/",toDelete);drawProgress(0)
info("Deleting "..(#toDelete-TotalFiles).." Files & Folders")

for k,v in ipairs(toDelete) do
  if v:sub(1,8) ~= "C:/.temp" then
    fs.remove(v) info("Removed",v)
  end
  drawProgress(k/#toDelete)
end

drawProgress()
status("Installing CraftOS...")

local CPath = TempDir.."drives/C/"
local DPath = TempDir.."drives/D/"

local toCopyD = index(DPath); drawProgress(0)
info("Copying "..(#toCopy).." Files & Folders")

for k=#toCopyD,1,-1 do
  local from, to = toCopyD[k], "D:/"..toCopyD[k]:sub(DPath:len()+1,-1)
  if fs.isDirectory(from) then
    fs.newDirectory(to) info("New Directory:",to)
  else
    local data = fs.read(from)
    fs.write(to,data) info("Copied File:",to)
  end
  drawProgress(1 - k/#toCopyD)
end

local toCopyC = index(CPath); drawProgress(0)
info("Copying "..(#toCopyD).." Files & Folders")

for k=#toCopyC,1,-1 do
  local from, to = toCopyC[k], "C:/"..toCopyC[k]:sub(CPath:len()+1,-1)
  if fs.isDirectory(from) then
    fs.newDirectory(to) info("New Directory:",to)
  else
    local data = fs.read(from)
    fs.write(to,data) info("Copied File:",to)
  end
  drawProgress(1 - k/#toCopyC)
end

status("Installation Complete !") drawProgress()

for i=5,1,-1 do
  info("Rebooting in "..i) clearEStack() sleep(1)
end

reboot()