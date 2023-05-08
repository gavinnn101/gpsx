if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
while not Lib.Loaded do
    game:GetService("RunService").Heartbeat:Wait()
end

local Client = require(game.ReplicatedStorage.Library.Client)
local RunService = game:GetService("RunService")
local tp = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)

debug.setupvalue(Invoke, 1, function() return true end)
debug.setupvalue(Fire, 1, function() return true end)

function GetComets(area)
    local returntable = {}
    local listCoins = Invoke("Get Coins")

    for i,v in pairs(listCoins) do
        local isComet = false
        for ie, ve in pairs(v) do
            if ie == "n" then
                if ve:match("Comet") then
                    isComet = true
                    break
                end
            end
        end

        if isComet and area == v.a then
            local coin = v
            coin["index"] = i
            table.insert(returntable, coin)
        end
    end
    return returntable
end

function UnlockTeleports()
    Lib.Gamepasses.Owns = function() return true end
    local teleportScript = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
    if teleportScript.UpdateAreas then
        teleportScript.UpdateAreas()
        teleportScript.UpdateBottom()
    end
end

function HopToNewServer()
    local Servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/6284583030/servers/Public?sortOrder=Asc&limit=100"))
    local success, errorMsg

    for i, v in pairs(Servers.data) do
        if v.playing ~= v.maxPlayers then
            print("Attempting to teleport to server: ", v.id)
            success, errorMsg = pcall(function()
                game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, v.id)
                repeat task.wait() until game.JobId == v.id and game:IsLoaded()
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

function AutoCollectLootBags()
    task.spawn(function()
        while true and game:IsLoaded() do
            local lootbags = game:GetService("Workspace")["__THINGS"]:FindFirstChild("Lootbags")
            for i,v in pairs(lootbags:GetChildren()) do
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
            local orbs = game:GetService("Workspace")["__THINGS"]:FindFirstChild("Orbs")
            for i,v in pairs(orbs:GetChildren()) do
                v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            end
            task.wait(1)
        end
    end)
end

-- Unlock teleports so we can get to the comets
UnlockTeleports()
-- auto collect loot
AutoCollectLootBags()
AutoCollectOrbs()

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
                        if game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index) then
                            print("Found child coin, idx: " ..cometCoinObjects[i].index)
                            for _, pet in pairs(myPets) do
                                print("pet loop, idx: " .. tostring(_))
                                task.spawn(function()
                                    FarmCoin(cometCoinObjects[i].index, pet.uid)
                                end)
                            end
                        end
                        repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index)
                        -- Wait for loot to get picked up before continuing
                        task.wait(6)
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