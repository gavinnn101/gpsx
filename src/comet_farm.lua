if not game:IsLoaded() then
    game.Loaded:Wait()
end

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

debug.setupvalue(Invoke, 1, function() return true end)
debug.setupvalue(Fire, 1, function() return true end)

function GetComets(area)
    local cometsFound = {}
    local listCoins = Invoke("Get Coins")
    -- Loop over coin data and find comets
    for i, v in pairs(listCoins) do
        if area == v.a and v.n:match("Comet") then
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

function HopToNewServer()
    local success, errorMsg

    while not success do
        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/6284583030/servers/Public?sortOrder=Asc&limit=100"))

        for _, v in ipairs(Servers.data) do
            if v.playing ~= v.maxPlayers then
                print("Attempting to teleport to server: ", v.id)
                success, errorMsg = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                    repeat RunService.RenderStepped:Wait() until game.JobId == v.id and game:IsLoaded()
                end)

                if success then
                    print("Successfully teleported to server: ", v.id)
                    break
                else
                    print("Failed to teleport to server: ", v.id, " Error: ", errorMsg)
                end
            end
        end
    end
end

function GetCometData()
    local cometsFound = {}
    local cometData, _ = Invoke("Comets: Get Data")

    local v32, v33, v34 = pairs(cometData);
    -- v32: some kind of function that gets comet data from the table. pairs? but why the 2nd param?
    print("v32: ", tostring(v32))
    -- v33: table, I think stores the comet data.
    print("v33: ", tostring(v33))
    -- v34: nil
    print("v34: ", tostring(v34))

    local cometID, cometData = v32(v33, v34);
    if cometID then
        local comet = {}
        -- Add comet to table
        print("v35: ", tostring(cometID))
        print("v36: ", tostring(cometData))
        -- skip if AreaId == Mystic Mine (Need Pet Overlord rank to unlock...)
        if cometData.AreaId == "Mystic Mine" then
            return {}
        end
        -- loop over v36 table
        for i, v in pairs(cometData) do
            comet[i] = v
            -- print values
            -- i: Type Mini     v: Comet
            -- i: CoinId        v: 3175
            -- i: EndTime       v: <int in seconds(I think)>
            -- i: Destroyed     v: false
            -- i: AreaId        v: Doodle Fairyland
            -- i: SpawnPosition v: <Position>
            -- i: Id unique id  v: (ex: 123abc-456def-789ghi)
            -- i: Speed         v: 30
            -- i: TimeCheck     v: <int in seconds(I think. probably current time?)>
            -- i: WorldId       v: Doodle
            -- i: EndPosition   v: <Position>
            -- print(i, v)
        end
        table.insert(cometsFound, comet)
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
                task.wait(5)
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
                task.wait(5)
            end
            task.wait(5)
        end
    end)
end

-- https://v3rmillion.net/showthread.php?tid=1119874
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(p1)
    if p1.Name == "ErrorPrompt" then
        print("Detected error prompt. Trying to rejoin game")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end
end)

-- Unlock teleports so we can get to the comets
UnlockTeleports()
-- auto collect loot
AutoCollectLootBags()
AutoCollectOrbs()
-- Auto triple damage to break comets faster
AutoTripleDamage()
-- Auto triple coins (not sure if triple coins helps with comets tbh but just in case.)
AutoTripleCoins()

while true do
    task.wait(1)
    local comets = GetCometData()
    if comets then
        if #comets > 0 then
            print("Found comet!")
            for _, comet in ipairs(comets) do
                if not comet["Destroyed"] then
                    local cometArea = tostring(comet["AreaId"])
                    print("Teleporting to comet: "  ..cometArea)
                    -- print comet data
                    for i, v in pairs(comet) do
                        print(i, v)
                    end
                    -- teleport to the comet's area
                    TeleportToArea(cometArea)
                    -- get coin data for area
                    local cometCoinObjects = GetComets(cometArea)
                    local myPets = GetMyPets()
                    for i = 1, #cometCoinObjects do
                        if Workspace["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index) then
                            print("Found child coin, idx: " ..cometCoinObjects[i].index)
                            for _, pet in pairs(myPets) do
                                print("pet loop, idx: " .. tostring(_))
                                FarmCoin(cometCoinObjects[i].index, pet.uid)
                            end
                        end
                        repeat task.wait() until not Workspace["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index) and #GetLootBags() == 0 and #GetOrbs() == 0
                    end
                else
                    print("Comet already destroyed.")
                end
            end
        else
            print("No comet found.")
            HopToNewServer()
        end
    end
end