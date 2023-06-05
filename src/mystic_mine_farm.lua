---@diagnostic disable: undefined-global

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

getgenv().settings = {
    fruitFarm = {
        FARM_FRUIT = true, -- Will farm fruit before farming mystic mine. 
        ORANGES_TO_FARM_TO = 150, -- Will farm fruit until we have this many oranges.
        MINIMUM_ORANGES = 100, -- Will go back to fruit farm if we have less than this many oranges.
    },

    platforms = {
        CREATE_PLATFORMS = true, -- Creates platform under farm area to hide from other players.
        MYSTIC_MINE_PLATFORM = "mysticMinePlatform", -- Name of the platform to create.
        PIXEL_VAULT_PLATFORM = "pixelVaultPlatform", -- Name of the platform to create.
    },

    serverHop = {
        SERVER_HOP = true, -- Server hop if the farm area runs out of coins.
        HOP_ON_TIMEOUT = true, -- Server hop if we've been in the same server for over TIMEOUT_THRESHOLD seconds.
        TIMEOUT_THRESHOLD = 600, -- Set the timeout duration in seconds
    },

    resourceSavers = {
        ENABLE_3D_RENDERING = true, -- false to save resources.
    },

    dataObjects = {
        DATA_FOLDER_NAME = "gpsx", -- Folder to save script related files in.
        DATA_FILE_NAME = "mystic_mine_farm.json", -- File to save script related data in.
    },

    muleGems = {
        MULE_GEMS = true, -- Mule gems to the main account.
        MULE_GEMS_THRESHOLD = 100000000000, -- Mule gems when we have more than this many. Default 100b.
        MAIL_RECIPIENT = "gavinnn1000", -- Account to mule gems to.
    },

    webhook = {
        WEBHOOK_ENABLED = true, -- Will send webhook notification when muling gems if enabled.
        WEBHOOK_URL = "https://discord.com/api/webhooks/960237304709013655/5icfh1TwM0pZEGNu2kclhInIYh7WhQ_BeIs5TLDvs4cGmOjHHE5boLFqk69ozGJUqxn_", -- Discord webhook url.
    },
}

-- Define full path to data file.
getgenv().settings.dataObjects.DATA_FILE_PATH = getgenv().settings.dataObjects.DATA_FOLDER_NAME .. "/" .. getgenv().settings.dataObjects.DATA_FILE_NAME

function UnlockTeleports()
    Lib.Gamepasses.Owns = function() return true end
    local teleportScript = getsenv(localPlayer.PlayerScripts.Scripts.GUIs.Teleport)
    if teleportScript.UpdateAreas then
        teleportScript.UpdateAreas()
        teleportScript.UpdateBottom()
    end
end

function TeleportToArea(area)
    set_thread_identity(2)
    tp.Teleport(area)
    set_thread_identity(7)
end

function GetMyPets()
    print("Returning equipped pets")
    return Lib.PetCmds.GetEquipped()
end

function FarmCoin(CoinID, PetID)
    print("farming coin (FarmCoin)")
    Invoke("Join Coin", CoinID, {PetID})
    Fire("Farm Coin", CoinID, PetID)
end

--returns all coins within the given area (area must be a table of conent)
function GetCoins(area)
    local coinTable = {}
    local listCoins = Invoke("Get Coins")
    for i,v in pairs(listCoins) do
        if area == v.a then
            local coin = v
            coin["index"] = i
            table.insert(coinTable, coin)
        end
    end
    return coinTable
end

function coinExists(coinIndex)
    return Workspace["__THINGS"].Coins:FindFirstChild(coinIndex) ~= nil
end

function farmMysticMine()
    local selectedAreas = {"Mystic Mine"}
    local myPets = GetMyPets()
    if myPets == nil then
        print("No equipped pets found.")
        return
    end

    for _,selectedArea in ipairs(selectedAreas) do  -- Iterate through each selected area
        task.wait(0.1)
        print("Looking for coins in area: " .. selectedArea)
        local coins = GetCoins(selectedArea)

        if #coins == 0 then
            if #GetLootBags() == 0 and #GetOrbs() == 0 then
                print("No coins found in area: " .. selectedArea)
                -- print total session time
                printSessionTime()
                -- Update total diamonds earned for session
                updateTotalDiamondsEarned()
                -- print total diamonds earned
                printTotalDiamondsEarned()
                if getgenv().settings.serverHop.SERVER_HOP then
                    print("Hopping servers (farmMysticMine)")
                    HopToNewServer()
                end
                return
            end
        else
            for i = 1, #coins do
                if coinExists(coins[i].index) then
                    print("Found child coin, idx: " .. coins[i].index)

                    for _, pet in pairs(myPets) do
                        print("Pet loop, idx: " .. tostring(_))
                        task.spawn(function()
                            FarmCoin(coins[i].index, pet.uid)
                        end)
                    end

                    print("Waiting for coin to break (idx: " .. coins[i].index .. ")")

                    local startTime = os.time()  -- Record the start time
                    repeat
                        task.wait()
                    until not coinExists(coins[i].index) or os.time() - startTime >= 30

                    if coinExists(coins[i].index) then
                        print("Coin still exists after timeout (idx: " .. coins[i].index .. ")")
                    else
                        print("Coin broken (idx: " .. coins[i].index .. ")")
                    end
                end
            end
        end
    end
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
        while task.wait(0.1) and game:IsLoaded() do
            local lootbags = GetLootBags()
            for _, v in ipairs(lootbags) do
                task.wait(0.1)
                v.CFrame = localPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end)

    Workspace['__THINGS'].Lootbags.ChildAdded:Connect(function(v)
        Fire("Collect Lootbag", v.Name, v.Position)
    end)
end

function AutoCollectOrbs()
    task.spawn(function()
        while task.wait(0.1) and game:IsLoaded() do
            local orbs = GetOrbs()
            for _, v in ipairs(orbs) do
                task.wait(0.1)
                v.CFrame = localPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end)

    Workspace['__THINGS'].Orbs.ChildAdded:Connect(function(v)
        Fire("Claim Orbs", {v.Name})
    end)
end

function AutoTripleDamage()
    task.spawn(function()
        while task.wait(1) and game:IsLoaded() do
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
        while task.wait(1) and game:IsLoaded() do
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
        while task.wait(1) and game:IsLoaded() do
            -- print("Checking for free gifts...")
            local txt = localPlayer.PlayerGui.FreeGiftsTop.Button.Timer.Text
            if txt == "Ready!" then
                print("Collecting gifts...")
                for i = 1,12 do
                    print("Collecting gift number: " .. i)
                    Invoke("Redeem Free Gift", i)
                    task.wait(1.2)
                end
            end
        end
    end)
end

function teleportToCenterOfMine()
    local centerOfMine = Vector3.new(9021.8193359375, -13.382338523864746, 2501.204833984375)
    local centerOfMineCFrame = CFrame.new(centerOfMine)
    local humanoidRootPart = localPlayer.Character.HumanoidRootPart

    if (humanoidRootPart.Position - centerOfMine).Magnitude > 1 then
        humanoidRootPart.CFrame = centerOfMineCFrame
    end

    print("Waiting for teleport to complete...")
    repeat task.wait() until (humanoidRootPart.Position - centerOfMine).Magnitude <= 1
    print("finished")
end


-- Function to create or move the platform under the player's current position
function CreatePlatform(platformName)
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart

        local platform = workspace:FindFirstChild(platformName)
        if not platform then
            -- Create the platform if it doesn't exist
            platform = Instance.new("Part")
            platform.Name = platformName
            platform.Parent = workspace
            platform.Anchored = true
            platform.Size = Vector3.new(100, 1, 100)
            platform.BrickColor = BrickColor.new("Baby blue")
            platform.Transparency = 0

            local gui = Instance.new("SurfaceGui")
            gui.Parent = platform
            gui.Face = Enum.NormalId.Top
            local textLabel = Instance.new("TextLabel")
            textLabel.Text = "Diamond mine farm GaviNNN#3281 <3"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundColor3 = Color3.new(1, 1, 1)
            textLabel.TextColor3 = Color3.new(0, 0, 0)
            textLabel.FontSize = Enum.FontSize.Size14
            textLabel.Parent = gui
            textLabel.TextScaled = true
        end

        -- Move the platform to a position 2 units under the player
        platform.Position = rootPart.Position + Vector3.new(0, -20, 0)
    end
end

-- Function to teleport the player to the platform
function TeleportToPlatform(platformName)
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart

        local platform = workspace:FindFirstChild(platformName)
        if platform then
            -- Teleport player to platform if the player is more than 5 units away
            local distanceToPlatform = (rootPart.Position - platform.Position).Magnitude
            if distanceToPlatform > 5 then
                rootPart.CFrame = CFrame.new(platform.Position + Vector3.new(0, 2, 0))
            end
        end
    end
end

function getOrangeCount()
    local boosts = localPlayer.PlayerGui.Main.Boosts
    return boosts:FindFirstChild("Orange") and tonumber(boosts.Orange.TimeLeft.Text:match("%d+")) or 0
end

function farmOranges()
    local CurrentFarmingPets = {}
    local selectedAreas = {"Pixel Vault"}
    local Things = Workspace["__THINGS"]
    local Coins = Things.Coins

    print("Getting equipped pets")
    local myPets = GetMyPets()

    local numPets = #myPets
    local coinFarmTimeout = 4

    for _,selectedArea in ipairs(selectedAreas) do  -- Iterate through each selected area
        local coins = GetCoins(selectedArea)

        for i = 1, #coins do
            task.wait(0.2)
            local petIndex = i % numPets + 1
            if not CurrentFarmingPets[myPets[petIndex]] then
                task.spawn(function()
                    local currentPet = myPets[petIndex]
                    local currentCoin = coins[i].index
                    CurrentFarmingPets[currentPet] = 'Farming'
                    FarmCoin(currentCoin, currentPet.uid)
                    local startTime = tick()
                    repeat task.wait(0.1) until not Coins:FindFirstChild(currentCoin) or (tick() - startTime >= coinFarmTimeout)
                    CurrentFarmingPets[currentPet] = nil
                end)
            end
            -- Only wait if we're at the last pet, otherwise continue immediately
            if i % numPets == numPets - 1 then
                task.wait(1) -- Increase the wait time here
            end
        end
        -- Increase the wait time here
        task.wait(1)
    end
end

-- Webhook alert for diamonds mailed.
function webhook(playerName, mailRecipient, diamondsSent)
    local url = getgenv().settings.webhook.WEBHOOK_URL

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

-- Mail all gems to getgenv().mailRecipient
function MailDiamonds()
    local mailboxCFrame = CFrame.new(254.149002, 98.2168579, 349.55304, 0.965907216, -6.73597569e-08, -0.258888513, 6.48122409e-08, 1, -1.83752729e-08, 0.258888513, 9.69664127e-10, 0.965907216)
    local localPlayerName = localPlayer.Name
    local mailRecipient = getgenv().settings.muleGems.MAIL_RECIPIENT
    local gemsToSend = GetPlayerCash("Diamonds") - 100000
    local msg = "Happy birthday!"
    print("Mailing " .. gemsToSend .. " gems to " .. mailRecipient .. " with message: " .. msg)
    TeleportToArea("Shop")
    task.wait(5)
    -- Teleport to mailbox
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = mailboxCFrame
    repeat task.wait() until game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame == mailboxCFrame
    Invoke("Send Mail", {
        ["Recipient"] = mailRecipient,
        ["Diamonds"] = gemsToSend,
        ["Pets"] = {},
        ["Message"] = msg
    })
    task.wait(1)
    if getgenv().settings.webhook.WEBHOOK_ENABLED then
        print("Sending webhook to alert that we mailed our gems.")
        webhook(localPlayerName, mailRecipient, gemsToSend)
    end
end

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
            local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
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
                    SafeWriteFile(getgenv().settings.dataObjects.DATA_FILE_PATH, HttpService:JSONEncode(file))
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
    repeat task.wait(0.1) until HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH)).serverList.data
    print("Got server list data. Continuing to hop.")
    local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
    print("Server list length: ", #file.serverList.data)
    for i,v in pairs(file.serverList.data) do
      if v.playing ~= v.maxPlayers and not file.visitedServers[v.id] then
        -- Add the server id to the visited servers.
        file.visitedServers[v.id] = true
        SafeWriteFile(getgenv().settings.dataObjects.DATA_FILE_PATH, HttpService:JSONEncode(file))
        print("teleporting to server: ", v.id)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
        repeat task.wait(0.1) until game:IsLoaded()
        return
      end
      task.wait(0.1)
    end
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

function StartSession()
    if not isfolder(getgenv().settings.dataObjects.DATA_FOLDER_NAME) then
        print("Creating gpsx folder.")
        makefolder(getgenv().settings.dataObjects.DATA_FOLDER_NAME)
    end
    local file
    if isfile(getgenv().settings.dataObjects.DATA_FILE_PATH) then
        file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))

        -- Print out the lastActiveTime and sessionStartTime values for debugging.
        print("Current lastActiveTime: " .. file.lastActiveTime)
        print("Current sessionStartTime: " .. file.sessionStartTime)

        local currentTime = os.time()
        local idleTime = os.difftime(currentTime, file.lastActiveTime)

        -- Print out the idleTime.
        print("Idle time: " .. idleTime)

        -- If the last activity was over 5 minutes ago (300 seconds), start a new session.
        if idleTime > 300 then
            print("Starting new session.")
            file.sessionStartTime = currentTime
            -- Reset the session-specific stats.
            file.totalDiamondsEarned = 0
            file.sessionStartRealTime = currentTime
        else
            print("Continuing existing session.")
        end
        file.lastActiveTime = currentTime
    else
        local currentTime = os.time()
        file = {
            sessionStartTime = currentTime,
            lastActiveTime = currentTime,
            serverListCacheTime = 0,
            serverList = {},
            visitedServers = {},
            totalDiamondsEarned = 0,
            sessionStartRealTime = currentTime,
        }
        print("Starting new session.")
    end
    SafeWriteFile(getgenv().settings.dataObjects.DATA_FILE_PATH, HttpService:JSONEncode(file))
    repeat task.wait(1) until isfile(getgenv().settings.dataObjects.DATA_FILE_PATH)
    print("StartSession wrote content to " ..getgenv().settings.dataObjects.DATA_FILE_PATH)
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

function CheckServerTimeout()
    local serverJoinTime = tick()
    task.spawn(function()
        print("Thread spawned for hopping after being in server for too long.")
        while task.wait(5) do
            -- Change to a new server if we've been in the current one for over serverTimeout.
            if (tick() - serverJoinTime) >= getgenv().settings.serverHop.TIMEOUT_THRESHOLD then
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

function isPlayerValid()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return true
    else
        return false
    end
end

function updateTotalDiamondsEarned()
    canServerHop = false
    local diamondsEarned = GetPlayerCash("Diamonds") - startDiamonds

    local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
    local totalDiamonedEarned = file.totalDiamondsEarned or 0 -- in case the variable isnt alreay in the file.
    file.totalDiamondsEarned = totalDiamonedEarned + diamondsEarned
    SafeWriteFile(getgenv().settings.dataObjects.DATA_FILE_PATH, HttpService:JSONEncode(file))
    canServerHop = true
end

function printTotalDiamondsEarned()
    local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
    local diamonds = file.totalDiamondsEarned or 0

    -- Convert the number to a more readable format
    local units = {"", "k", "m", "b"}
    local unitIndex = 1
    while diamonds >= 1000 do
        diamonds = diamonds / 1000
        unitIndex = unitIndex + 1
    end

    -- Round to one decimal place and append the correct unit
    diamonds = math.floor(diamonds * 10 + 0.5) / 10
    local diamondsStr = tostring(diamonds) .. units[unitIndex]

    print("Total Diamonds Earned This Session: " .. diamondsStr)
end

function printSessionTime()
    local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
    local startRealTime = file.sessionStartRealTime
    local elapsed = os.difftime(os.time(), startRealTime)

    local seconds = elapsed % 60
    local minutes = math.floor((elapsed / 60) % 60)
    local hours = math.floor((elapsed / (60 * 60)) % 24)
    local days = math.floor(elapsed / (60 * 60 * 24))

    local formattedTime = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
    print("Total Session Time: " .. formattedTime)
end

function UpdateCheckInTime()
    task.spawn(function()
        while task.wait(10) do
            canServerHop = false
            local file = HttpService:JSONDecode(SafeReadFile(getgenv().settings.dataObjects.DATA_FILE_PATH))
            file.lastActiveTime = os.time()
            SafeWriteFile(getgenv().settings.dataObjects.DATA_FILE_PATH, HttpService:JSONEncode(file))
            print("Wrote new last active time: " ..file.lastActiveTime .." to file: " ..getgenv().settings.dataObjects.DATA_FILE_PATH)
            canServerHop = true
        end
    end)
end

function getCoinMultiplier(coinB)
-- pass in coin.b when looping over Invoke("Get Coins")
    if not coinB then return 0 end
    local totalMultiplier = 0
    if coinB.l then
        for _, v in pairs(coinB.l) do
            pcall(function()
                if v.m and tonumber(v.m) then
                    totalMultiplier = totalMultiplier + v.m
                end
            end)
        end
    end
    return totalMultiplier
end

function main()
    -- Make sure we load into the server or hop otherwise.
    EnsureServerLoads()
    print("Game loaded")

    -- Thread to update check-in time every minute.
    UpdateCheckInTime()

    Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
    while not Lib.Loaded do
        RunService.Heartbeat:Wait()
    end

    local Network = require(ReplicatedStorage.Library.Client.Network)
    Fire, Invoke = Network.Fire, Network.Invoke

    -- Hook Fire/Invoke
    local old = hookfunction(getupvalue(Fire, 1), function(...)
        return true
    end)

    localPlayer = Players.LocalPlayer
    tp = getsenv(localPlayer.PlayerScripts.Scripts.GUIs.Teleport)

    if not getgenv().settings.resourceSavers.ENABLE_3D_RENDERING then
        -- Disable 3d rendering.
        print("Disabling 3D Rendering to save cpu.")
        RunService:Set3dRenderingEnabled(getgenv().settings.resourceSavers.ENABLE_3D_RENDERING)
    end

    if getgenv().settings.serverHop.SERVER_HOP then
        -- Start thread to handle getting a fresh server list
        CacheServerList()
        -- Flag so we don't hop while trying to write to a file or similar.
        canServerHop = true
        -- Tracks session stats in a json file
        StartSession()
        -- Hop servers if we get an error prompt (error 277, 279, etc)
        HopOnErrorPrompt()
        if getgenv().settings.serverHop.HOP_ON_TIMEOUT then
            CheckServerTimeout()
        end
    end

    -- Auto loot orbs / lootbags
    AutoCollectLootBags()
    AutoCollectOrbs()

    -- Auto triple damage / coins
    AutoTripleDamage()
    AutoTripleCoins()
    -- Auto collect free gifts
    AutoCollectFreeGifts()
    -- Unlock teleports to get to mystic mine / pixel vault / etc.
    UnlockTeleports()

    startDiamonds = GetPlayerCash("Diamonds")

    printSessionTime()
    printTotalDiamondsEarned()

    -- Farm loop
    local currentArea = nil
    while true do
        -- Mail diamonds to MAIL_RECIPIENT
        if getgenv().settings.muleGems.MULE_GEMS then
            local diamonds = GetPlayerCash("Diamonds")
            if tonumber(diamonds) > getgenv().settings.muleGems.MULE_GEMS_THRESHOLD then
                MailDiamonds()
            end
        end
        -- Farm fruit / oranges before diamond farming if enabled.
        if getgenv().settings.fruitFarm.FARM_FRUIT and getOrangeCount() < getgenv().settings.fruitFarm.MINIMUM_ORANGES then
            if currentArea ~= "Pixel Vault" and isPlayerValid() then
                task.wait(1)
                TeleportToArea("Pixel Vault")
                if getgenv().settings.platforms.CREATE_PLATFORMS then
                    task.wait(1)
                    CreatePlatform(getgenv().settings.platforms.PIXEL_VAULT_PLATFORM)
                    task.wait(1)
                    TeleportToPlatform(getgenv().settings.platforms.PIXEL_VAULT_PLATFORM)
                end
                currentArea = "Pixel Vault"
            end
            while getOrangeCount() < getgenv().settings.fruitFarm.ORANGES_TO_FARM_TO do
                print("Farming oranges... Current count: " .. getOrangeCount() .. " total needed: " .. getgenv().settings.fruitFarm.ORANGES_TO_FARM_TO)
                farmOranges()
            end
        end
        -- Teleport to mystic mine if needed then farm diamonds.
        if currentArea ~= "Mystic Mine" and isPlayerValid() then
            task.wait(1)
            -- Teleport to farm area.
            TeleportToArea("Mystic Mine")
            task.wait(1)
            -- Move character to center of mine area
            teleportToCenterOfMine()
            if getgenv().settings.platforms.CREATE_PLATFORMS then
                task.wait(1)
                -- Create a platform to hide on
                CreatePlatform(getgenv().settings.platforms.MYSTIC_MINE_PLATFORM)
                task.wait(1)
                -- Teleport to platform
                TeleportToPlatform(getgenv().settings.platforms.MYSTIC_MINE_PLATFORM)
            end
            currentArea = "Mystic Mine"
        end
        -- Farm mystic mine if we don't need to farm fruit.
        farmMysticMine()
    end
end

main()
