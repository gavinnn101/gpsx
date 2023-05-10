pcall(function()
    repeat
        task.wait()
    until game:IsLoaded()
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

local tp = getsenv(Players.LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)

local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
while not Lib.Loaded do
    RunService.Heartbeat:Wait()
end

local _coins = Workspace["__THINGS"].Coins

debug.setupvalue(Invoke, 1, function() return true end)
debug.setupvalue(Fire, 1, function() return true end)

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

function HopToNewServer(maxRetries, retryDelay)
    maxRetries = maxRetries or 5  -- Default to 5 retries if not provided
    retryDelay = retryDelay or 5  -- Default to 5 seconds delay if not provided

    local success, errorMsg
    local retryCount = 0

    while not success and retryCount < maxRetries do
        local _success, Servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/6284583030/servers/Public?sortOrder=Asc&limit=100"))
        end)

        for _, v in ipairs(Servers.data) do
            if v.playing ~= v.maxPlayers then
                print("Attempting to teleport to server: ", v.id)
                success, errorMsg = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                    -- I think commenting this out will potentially fix getting stuck in a server when we hit a teleport error.
                    -- repeat RunService.RenderStepped:Wait() until game.JobId == v.id and game:IsLoaded()
                end)

                if success then
                    print("Successfully teleported to server: ", v.id)
                    break
                else
                    print("Failed to teleport to server: ", v.id, " Error: ", errorMsg)
                    retryCount = retryCount + 1
                    task.wait(retryDelay)
                end
            end
        end
    end

    if retryCount >= maxRetries then
        print("Exceeded maximum retries. Unable to teleport to a new server.")
    end
end

function GetCometData()
    local cometsFound = {}
    local cometTable, _ = Invoke("Comets: Get Data")

    for cometID, cometData in pairs(cometTable) do
        -- skip if AreaId == Mystic Mine (Need Pet Overlord rank and lose 1 huge pet to unlock!)
        if cometData.AreaId ~= "Mystic Mine" then
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
        end
    end
    return cometsFound
end

function TeleportToArea(area)
    task.spawn(function()
        task.wait(0.1)
        set_thread_identity(2)
        tp.Teleport(area)
    end)
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
        while true and game:IsLoaded() do
            local lootbags = GetLootBags()
            for _, v in ipairs(lootbags) do
                v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                task.wait(0.1)
            end
            task.wait(1)
        end
    end)
end

function AutoCollectOrbs()
    task.spawn(function()
        while true and game:IsLoaded() do
            local orbs = GetOrbs()
            for _, v in ipairs(orbs) do
                v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                task.wait(0.1)
            end
            task.wait(1)
        end
    end)
end

function AutoTripleDamage()
    task.spawn(function()
        while true and game:IsLoaded() do
            -- activate triple damage "potion" if not already active
            local Save = Lib.Save.Get()
            if Save["Boosts"]["Triple Damage"] == nil or Save["Boosts"]["Triple Damage"] < 60 then
                print("Activating triple damage")
                Fire("Activate Boost", "Triple Damage")
                task.wait(1)
            end
            task.wait(5)
        end
    end)
end

function AutoTripleCoins()
    task.spawn(function()
        while true and game:IsLoaded() do
            -- activate triple coins "potion" if not already active
            local Save = Lib.Save.Get()
            if Save["Boosts"]["Triple Coins"] == nil or Save["Boosts"]["Triple Coins"] < 60 then
                print("Activating triple coins")
                Fire("Activate Boost", "Triple Coins")
                task.wait(1)
            end
            task.wait(5)
        end
    end)
end

function AutoCollectFreeGifts()
    task.spawn(function()
        while true and game:IsLoaded() do
            -- print("Checking for free gifts...")
            local txt = game:GetService("Players").LocalPlayer.PlayerGui.FreeGiftsTop.Button.Timer.Text
            if txt == "Ready!" then
                print("Collecting gifts...")
                for i = 1,12 do
                    print("Collecting gift number: " .. i)
                    Invoke("Redeem Free Gift", i)
                    task.wait(1.2)
                end
            else
                print("Free gifts aren't ready to collect...")
                task.wait(60)
            end
            task.wait(1)
        end
    end)
end

function main()
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

    local serverTimeout = 200 -- Set the timeout duration in seconds
    local serverJoinTime = tick()

    while true do
        -- https://v3rmillion.net/showthread.php?tid=1119874
        if game.CoreGui.RobloxPromptGui.promptOverlay:FindFirstChild("ErrorPrompt") then
            print("Detected error prompt. Trying to join new game")
            HopToNewServer()
        end

        -- Change to a new server if we've been in the current one for over ~2 minutes. Could be an unreachable comet or similar.
        if tick() - serverJoinTime >= serverTimeout then
            print("Timeout reached. Hopping to a new server.")
            HopToNewServer()
            serverJoinTime = tick()
        end

        task.wait(1)
        local comets = GetCometData()
        if #comets == 0 then
            print("No comet found. Changing servers.")
            HopToNewServer()
            return
        end

        print("Found comet!")

        for _, comet in ipairs(comets) do
            if comet["Destroyed"] then
                print("Comet already destroyed.")
                continue
            end

            local cometArea = tostring(comet["AreaId"])
            print("Teleporting to comet: " .. cometArea)

            -- print comet data
            for i, v in pairs(comet) do
                print(i, v)
            end

            -- teleport to the comet's area
            TeleportToArea(cometArea)

            -- get coin data for area
            local cometCoinObjects = GetComets(cometArea)
            for i = 1, #cometCoinObjects do
                if not _coins:FindFirstChild(cometCoinObjects[i].index) then
                    continue
                end

                print("Found child coin, idx: " .. cometCoinObjects[i].index)

                local myPets = GetMyPets()
                for _, pet in pairs(myPets) do
                    print("pet loop, idx: " .. tostring(_))
                    FarmCoin(cometCoinObjects[i].index, pet.uid)
                end
                repeat task.wait() until not _coins:FindFirstChild(cometCoinObjects[i].index) and #GetLootBags() == 0 and #GetOrbs() == 0
            end
        end
    end
end

main()