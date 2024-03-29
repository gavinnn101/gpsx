---@diagnostic disable: undefined-global

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local dataFolderName = "gpsx"
local dataFileName = dataFolderName .. "/" .. "comet_farm.json"

getgenv().webhookUrl = "https://discord.com/api/webhooks/960237304709013655/5icfh1TwM0pZEGNu2kclhInIYh7WhQ_BeIs5TLDvs4cGmOjHHE5boLFqk69ozGJUqxn_"
getgenv().mailRecipient = "gavinnn1000"
   
function SafeWriteFile(filename, content)
    local ret = nil
    canServerHop = false

    local success, err = pcall(function()
        writefile(filename, content)
    end)

    if not success then
        print("An error occurred while writing to the file: ".. err)
        ret = false
    else
        ret = true
    end
    canServerHop = true
    return ret
end

function SafeReadFile(filename)
    local ret = nil
    canServerHop = false

    local success, resultOrErr = pcall(function()
        return readfile(filename)
    end)

    if not success then
        print("An error occurred while reading the file: ".. resultOrErr)
        ret = nil
    else
        ret = resultOrErr
    end
    canServerHop = true
    return ret
end

function CacheServerList()
    task.spawn(function()
        print("Thread spawned for caching server list to file.")
        while task.wait(10) do
            local file = HttpService:JSONDecode(SafeReadFile(dataFileName))
            if not file or (tick() - file.serverListCacheTime) > 60 then
                canServerHop = false
                print("Getting new server list.")
                local success, servers = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/6284583030/servers/Public?sortOrder=Asc&limit=100"))
                end)
                -- Only update the file if the HTTP request is successful and JSON can be parsed.
                if success then
                    file.serverList = servers
                    file.serverListCacheTime = tick()
                    -- Reset the visited servers when getting a new server list.
                    file.visitedServers = {}
                    SafeWriteFile(dataFileName, HttpService:JSONEncode(file))
                    print("Wrote new server list to file.")
                    canServerHop = true
                else
                    print("Failed to get server list. HTTP request unsuccessful or JSON could not be parsed.")
                end
            -- else
            --     local timeLeft = 60 - (tick() - file.serverListCacheTime)
            --     print("Server list is still cached. Will refresh in " .. timeLeft .. " seconds.")
            end
        end
    end)
end

function HopToNewServer()
    -- Make sure CacheServerList has created an initial list before hopping.
    print("Waiting for valid server list data before hopping")
    repeat task.wait(0.1) until HttpService:JSONDecode(SafeReadFile(dataFileName)).serverList.data
    print("Got server list data. Continuing to hop.")
    local file = HttpService:JSONDecode(SafeReadFile(dataFileName))
    print("Server list length: ", #file.serverList.data)
    for i,v in pairs(file.serverList.data) do
      if v.playing ~= v.maxPlayers and not file.visitedServers[v.id] then
        -- Add the server id to the visited servers.
        file.visitedServers[v.id] = true
        SafeWriteFile(dataFileName, HttpService:JSONEncode(file))
        print("teleporting to server: ", v.id)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
        repeat task.wait(0.1) until game:IsLoaded()
        return
      end
      task.wait(0.1)
    end
end

function StartSession()
    if not isfolder(dataFolderName) then
        print("Creating gpsx folder.")
        makefolder(dataFolderName)
    end
    local file
    if isfile(dataFileName) then
        file = HttpService:JSONDecode(SafeReadFile(dataFileName))
        file.checkInTime = tick()
        -- If the last check-in was over 5 minutes ago (300 seconds), start a new session.
        if (file.checkInTime - file.sessionStartTime) > 300 then
            file.sessionStartTime = file.checkInTime
            -- Reset the cometsFound counter at the start of a new session.
            file.cometsFound = 0
            print("Starting new session.")
        else
            print("Continuing existing session.")
        end
    else
        file = {
            sessionStartTime = tick(),
            checkInTime = tick(),
            serverListCacheTime = 0,
            serverList = {},
            visitedServers = {},
            cometsFound = 0,  -- Initialize the cometsFound counter.
        }
        print("Starting new session.")
    end
    SafeWriteFile(dataFileName, HttpService:JSONEncode(file))
    repeat task.wait(1) until isfile(dataFileName)
    print("StartSession wrote content to " ..dataFileName)
end

function HopOnErrorPrompt()
    -- hop to a new server if we get an error prompt
    task.spawn(function()
        print("Thread spawned for hopping on error prompt.")
        while task.wait(5) do
            if game.CoreGui.RobloxPromptGui.promptOverlay:FindFirstChild("ErrorPrompt") then
                print("Error prompt detected. Hopping to a new server.")
                task.wait(5)
                HopToNewServer()
            end
        end
    end)
end

function GetComets(area)
    local cometsFound = {}
    local listCoins = Invoke("Get Coins")
    -- Loop over coin data and find comets
    for i, v in pairs(listCoins) do
        if area == v.a and v.n:match("Comet") then
            print("Adding found comet 'coin' to table")
            local coin = v
            coin["index"] = i
            table.insert(cometsFound, coin)
        end
        -- task.wait(0.1)
    end
    return cometsFound
end

function UnlockTeleports()
    Lib.Gamepasses.Owns = function() return true end
    local teleportScript = getsenv(Players.LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
    if teleportScript.UpdateAreas then
        teleportScript.UpdateAreas()
        teleportScript.UpdateBottom()
    end
end

function GetCometData()
    local cometsFound = {}
    local cometTable, _ = Invoke("Comets: Get Data")

    for cometID, cometData in pairs(cometTable) do
        -- skip if AreaId == Mystic Mine (Need Pet Overlord rank and lose 1 huge pet to unlock!)
        -- Cyber Cavern requires account to be at least 7 days old.
        -- Paradise Cave requires account to be at least 1 day old.
        if cometData.AreaId ~= "Mystic Mine" and cometData.AreaId ~= "Cyber Cavern" and cometData.AreaId ~= "Paradise Cave" then
            local comet = {}
            -- loop over cometData table
            for i, v in pairs(cometData) do
                comet[i] = v
--             -- print values
--             -- i: Type Mini     v: Comet
--             -- i: CoinId        v: 3175
--             -- i: EndTime       v: <int in seconds(I think)>
--             -- i: Destroyed     v: false
--             -- i: AreaId        v: Doodle Fairyland
--             -- i: SpawnPosition v: <Position>
--             -- i: Id unique id  v: (ex: 123abc-456def-789ghi)
--             -- i: Speed         v: 30
--             -- i: TimeCheck     v: <int in seconds(I think. probably current time?)>
--             -- i: WorldId       v: Doodle
--             -- i: EndPosition   v: <Position>
            end
            table.insert(cometsFound, comet)
            -- task.wait(0.1)
        end
        -- task.wait(0.1)
    end
    return cometsFound
end

function TeleportToArea(area)
    set_thread_identity(2)
    tp.Teleport(area)
    set_thread_identity(7)
end

function FarmCoin(CoinID, PetID)
    print("farming coin (FarmCoin)")
    Invoke("Join Coin", CoinID, {PetID})
    Fire("Farm Coin", CoinID, PetID)
end

function GetMyPets()
    print("Returning equipped pets")
    return Lib.PetCmds.GetEquipped()
end

-- Returns table of lootbags
function GetLootBags()
    local lootbags = Workspace["__THINGS"]:FindFirstChild("Lootbags")
    return lootbags:GetChildren()
end

-- Returns table of orbs
function GetOrbs()
    local orbs = Workspace["__THINGS"]:FindFirstChild("Orbs")
    return orbs:GetChildren()
end

function AutoCollectLootBags()
    task.spawn(function()
        while task.wait(1) and game:IsLoaded() do
            local lootbags = GetLootBags()
            for _, v in ipairs(lootbags) do
                v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                task.wait(0.1)
            end
        end
    end)
end

function AutoCollectOrbs()
    task.spawn(function()
        while task.wait(1) and game:IsLoaded() do
            local orbs = GetOrbs()
            for _, v in ipairs(orbs) do
                v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                task.wait(0.1)
            end
        end
    end)
end

function AutoTripleDamage()
    task.spawn(function()
        while task.wait(5) and game:IsLoaded() do
            -- activate triple damage "potion" if not already active
            local Save = Lib.Save.Get()
            if Save["Boosts"]["Triple Damage"] == nil or Save["Boosts"]["Triple Damage"] < 60 then
                print("Activating triple damage")
                Fire("Activate Boost", "Triple Damage")
            end
        end
    end)
end

function AutoTripleCoins()
    task.spawn(function()
        while task.wait(5) and game:IsLoaded() do
            -- activate triple coins "potion" if not already active
            local Save = Lib.Save.Get()
            if Save["Boosts"]["Triple Coins"] == nil or Save["Boosts"]["Triple Coins"] < 60 then
                print("Activating triple coins")
                Fire("Activate Boost", "Triple Coins")
            end
        end
    end)
end

function AutoCollectFreeGifts()
    task.spawn(function()
        while task.wait(5) and game:IsLoaded() do
            -- print("Checking for free gifts...")
            local txt = Players.LocalPlayer.PlayerGui.FreeGiftsTop.Button.Timer.Text
            if txt == "Ready!" then
                print("Collecting gifts...")
                for i = 1,12 do
                    print("Collecting gift number: " .. i)
                    Invoke("Redeem Free Gift", i)
                    task.wait(1.2)
                end
            -- else
            --     print("Free gifts aren't ready to collect...")
            --     task.wait(60)
            end
        end
    end)
end

function ProcessComet(comet)
    local cometArea = tostring(comet["AreaId"])

    -- print comet data
    for i, v in pairs(comet) do
        -- task.wait(0.1)
        print(i, v)
    end

    -- wait until localplayer rootpart is valid
    print("Waiting for localplayer rootpart to be valid.")
    repeat task.wait() until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- teleport to the comet's area
    print("Teleporting to comet: " .. cometArea)
    TeleportToArea(cometArea)

    -- get coin data for area
    local cometCoinObjects = GetComets(cometArea)
    for i = 1, #cometCoinObjects do
        -- task.wait(0.1)
        if not _coins:FindFirstChild(cometCoinObjects[i].index) then
            continue
        end

        print("Found child coin, idx: " .. cometCoinObjects[i].index)

        local myPets = GetMyPets()
        for _, pet in pairs(myPets) do
            -- task.wait(0.1)
            print("pet loop, idx: " .. tostring(_))
            FarmCoin(cometCoinObjects[i].index, pet.uid)
        end
        print("Waiting for coin to be destroyed and all lootbags to be collected.")
        repeat task.wait(1) until not _coins:FindFirstChild(cometCoinObjects[i].index) and #GetLootBags() == 0 and #GetOrbs() == 0
        -- Increment the cometsFound counter and save to the file.
        canServerHop = false
        local file = HttpService:JSONDecode(SafeReadFile(dataFileName))
        file.cometsFound = file.cometsFound + 1
        print("Comets found during session: " .. tostring(file.cometsFound))
        SafeWriteFile(dataFileName, HttpService:JSONEncode(file))
        canServerHop = true
    end
end

function CheckServerTimeout()
    local serverTimeout = 300 -- Set the timeout duration in seconds
    local serverJoinTime = tick()
    task.spawn(function()
        print("Thread spawned for hopping after being in server for too long.")
        while task.wait(5) do
            -- Change to a new server if we've been in the current one for over ~2 minutes. Could be an unreachable comet or similar.
            if (tick() - serverJoinTime) >= serverTimeout then
                print("Timeout reached. Hopping to a new server.")
                HopToNewServer()
                serverJoinTime = tick()
            -- else
            --     -- print time remaining until timeout
            --     print("Timeout in: " .. tostring(serverTimeout - (tick() - serverJoinTime)))
            end
        end
    end)
end

function EnsureServerLoads()
    -- Server hop if we get stuck in the load screen. This solves error code 279.
    print("Waiting for game to load... (EnsureServerLoads)")
    local success, errorMsg = pcall(function()
        local timer = 60
        while task.wait(1) and timer > 0 and not game:IsLoaded() do
            timer = timer - 1
        end
        if timer == 0 then
            print("Timed out loading into server. Hopping to a new server.")
            HopToNewServer()
        end
    end)

    if not success then
        print("Error occurred: ", errorMsg)
        HopToNewServer()
    end
end

-- Function to format a number with commas
local function formatNumber(number)
    return tostring(number):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Webhook alert for diamonds mailed.
function webhook(playerName, mailRecipient, diamondsSent)
    local url = getgenv().webhookUrl

    local unixtime = os.time()
    local format = "%H:%M:%S | %a, %d %b %Y"
    local timei = os.date(format, unixtime)

    local embed = {
        ["title"] = "Gems sent from bot alert!",
        ["color"] = tonumber("0x00FF00", 16), -- Green
        ["fields"] = {
            {
                ["name"] = "Diamonds sent: ",
                ["value"] = formatNumber(diamondsSent),
                ["inline"] = false
            },
            {
                ["name"] = "Sending Player: ",
                ["value"] = playerName,
                ["inline"] = false
            },
            {
                ["name"] = "Receiving Player: ",
                ["value"] = mailRecipient,
                ["inline"] = false
            }
        },
            ["footer"] = {text = timei}
		}
		
	(syn and syn.request or http_request or http.request) {
		Url = url;
		Method = 'POST';
		Headers = {
			['Content-Type'] = 'application/json';
		};
		Body = HttpService:JSONEncode({
			username = "Gem Tracker",
			avatar_url = 'https://avatars.githubusercontent.com/u/41026935?v=4',
			embeds = {embed}
		})
	}
end

function GetPlayerCash(coin)
    local amountstr = game.Players.LocalPlayer.PlayerGui.Main.Right[coin].Amount.Text
    local amountstrnocomas = amountstr:gsub("%D", "")
    return tonumber(amountstrnocomas)
end

-- Mail all gems
function MailDiamonds()
    canServerHop = false
    local localPlayerName = game.Players.LocalPlayer.Name
    local mailRecipient = getgenv().mailRecipient
    local gemsToSend = GetPlayerCash("Diamonds") - 100000
    local msg = "Happy birthday!"
    print("Mailing " .. gemsToSend .. " gems to " .. mailRecipient .. " with message: " .. msg)
    TeleportToArea("Shop")
    task.wait(5)
    -- Teleport to mailbox
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(254.149002, 98.2168579, 349.55304, 0.965907216, -6.73597569e-08, -0.258888513, 6.48122409e-08, 1, -1.83752729e-08, 0.258888513, 9.69664127e-10, 0.965907216)
    task.wait(1)
    Invoke("Send Mail", {
        ["Recipient"] = mailRecipient,
        ["Diamonds"] = gemsToSend,
        ["Pets"] = {},
        ["Message"] = msg
    })
    task.wait(1)
    print("Sending webhook to alert that we mailed our gems.")
    webhook(localPlayerName, mailRecipient, gemsToSend)
    canServerHop = true
end

function postUserStats(playerName, currentDiamondsEarned)
    local url = 'http://localhost:5000/api/v1/stats'  -- Change this to your API's URL

    local requestBody = {
        username = playerName,
        current_run_time = tick(),
        current_diamonds_earned = currentDiamondsEarned
    }

    (syn and syn.request or http_request or http.request) {
        Url = url,
        Method = 'POST',
        Headers = {
            ['Content-Type'] = 'application/json'
        },
        Body = HttpService:JSONEncode(requestBody)
    }
end

-- Check teleport status and server hop if the teleport failed.
TeleportService.TeleportInitFailed:Connect(function(player, resultEnum, msg)
    task.wait(5)
    if resultEnum == Enum.TeleportResult.Success then
        print("Teleport success.")
    elseif resultEnum == Enum.TeleportResult.IsTeleporting then
        print("Teleport already in progress.")
    elseif resultEnum == Enum.TeleportResult.GameFull then
        print("Tried to join a full server. Hopping to a new server.")
        HopToNewServer()
    elseif resultEnum == Enum.TeleportResult.Failure or resultEnum == Enum.TeleportResult.GameNotFound or resultEnum == Enum.TeleportResult.GameEnded or resultEnum == Enum.TeleportResult.Flooded or resultEnum == Enum.TeleportResult.Unauthorized then
        local fmt = string.format('server: teleport %s failed, resultEnum:%s, msg:%s',player.Name, tostring(resultEnum), msg)
        print(fmt)
        print("Teleport failed because of a server error Failure / GameNotFound / GameEnded / Flooded / Unauthorized. Hopping to a new server.")
        HopToNewServer()
    end
end)

function main()
    -- Make sure we load into the server or hop otherwise.
    EnsureServerLoads()
    print("Game loaded")
    -- Disable 3d rendering.
    print("Disabling 3D Rendering to save cpu.")
    RunService:Set3dRenderingEnabled(false)
    -- Flag so we don't hop while trying to write to a file or similar.
    canServerHop = true
    -- Tracks session stats in a json file
    StartSession()
    -- Hop servers if we get an error prompt (error 277, 279, etc)
    HopOnErrorPrompt()
    -- Server hop if we've been in the server for over 2 minutes.
    CheckServerTimeout()
    -- Start thread to handle getting a fresh server list
    CacheServerList()

    Network = require(ReplicatedStorage.Library.Client.Network)
    Fire, Invoke = Network.Fire, Network.Invoke

    -- Hook Fire/Invoke to bypass AC
    old = hookfunction(getupvalue(Fire, 1), function(...)
        return true
       end)

    -- Check comet data first thing for more comets per hour.
    local comets = GetCometData()
    if #comets == 0 then
        print("No comets found. Changing servers. (Start of main.)")
        HopToNewServer()
    else
        print("Found comet on server. Continuing.")
    end

    tp = getsenv(Players.LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)

    Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
    while not Lib.Loaded do
        RunService.Heartbeat:Wait()
    end

    _coins = Workspace["__THINGS"].Coins


    -- Unlock teleports so we can get to the comets
    UnlockTeleports()
    -- auto collect loot
    AutoCollectLootBags()
    AutoCollectOrbs()
    -- Auto triple damage to break comets faster
    AutoTripleDamage()
    -- Auto triple coins (not sure if triple coins helps with comets tbh but just in case.)
    AutoTripleCoins()
    -- Auto collect free gifts (may as well try for huge cupcake.)
    -- Might want to turn off in some scenarios if you want to collect the gifts in a certain area for all the coins you get in the last 2.
    AutoCollectFreeGifts()

    task.spawn(function()
        print("Spawning thread to run the main loop")
        while task.wait() do
            print("main loop")
            comets = GetCometData()
            if #comets == 0 then    
                -- Mail diamonds if needed while theres no comet to farm.
                local diamonds = GetPlayerCash("Diamonds")
                if tonumber(diamonds) > 100000000000 then
                    MailDiamonds()
                end
                -- Hop to new server as long as we're allowed to. (Not wring to file, etc.)
                if canServerHop then
                    print("No comet found. Changing servers.")
                    HopToNewServer()
                    return
                else
                    print("No comet found. Waiting until canServerHop.")
                    repeat task.wait(1) until canServerHop
                end
            end

            print("Found comet!")

            for _, comet in ipairs(comets) do
                if not comet["Destroyed"] then
                    ProcessComet(comet)
                    break
                else
                    print("Comet already destroyed.")
                end
                -- task.wait(0.1)
            end
        end
    end)
end

main()