---@diagnostic disable: undefined-global

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Util = {}

local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
while not Lib.Loaded do
    game:GetService("RunService").Heartbeat:Wait()
end

local Client = require(game.ReplicatedStorage.Library.Client)
local RunService = game:GetService("RunService")
local tp = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
local menus = game.Players.LocalPlayer.PlayerGui.Main.Right

-- Hooking the _check function to bypass the anticheat (Blunder) environment check.
debug.setupvalue(Invoke, 1, function() return true end)
debug.setupvalue(Fire, 1, function() return true end)

function Util.notify(msg)
    local Notify = getsenv(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Admin Commands"):WaitForChild("Admin Cmds Client")).AddNotification
    Notify(msg)
    print(msg)
end

function Util.isInList(list, playerName)
    for _, name in ipairs(list) do
        if playerName == name then
            return true
        end
    end
    return false
end

function Util.loadAccounts()
    -- Check if gpsx folder exists and create it if it doesnt.
    if not isfolder("gpsx") then
        print("Creating gpsx folder")
        makefolder("gpsx")
    end
    -- check if accounts.json file exists and create it if it doesnt.
    if not isfile("gpsx/accounts.json") then
        print("Creating accounts.json")
        writefile("gpsx/accounts.json", "{}")
    end
    -- Load accounts from JSON file
    print("Loading accounts.json")
    local HttpService = game:GetService('HttpService')
    local accounts = HttpService:JSONDecode(readfile("gpsx/accounts.json"))
    return accounts
end

function Util.bypassAC()
    -- https://v3rmillion.net/showthread.php?tid=1198487
    local Blunder = require(game:GetService("ReplicatedStorage"):FindFirstChild("BlunderList", true))
    local OldGet = Blunder.getAndClear

    setreadonly(Blunder, false)

    local function OutputData(Message)
       rconsoleprint("@@RED@@")
       rconsoleprint(Message .. "\n")
    end

    Blunder.getAndClear = function(...)
       local Packet = ...
       for i,v in next, Packet.list do
           if v.message ~= "PING" then
               OutputData(v.message)
               table.remove(Packet.list, i)
           end
       end
       return OldGet(Packet)
    end
end

function Util.GetEggData()
    -- eggsData - egg attributes
    -- isGolden: bool
    -- eggRequiredOpenAmount: int
    -- disabled: bool
    -- cost: int
    -- displayName: string
    -- eggRequired: nil
    -- hatchable: bool
    -- drops: table: memory address?
    -- model: model type? (Egg)
    -- areaRequired: bool
    -- hardcoreEnabled: bool
    -- currency: coin type (Coins, Rainbow Coins, Fantasy Coins)
    -- area: in-game area (Winter, Forest, Axolotl Deep Ocean) (this is also the area mapped to the egg dispenser)

    --Generate Egg Data
    local eggsData = {}
    -- Loop over Eggs / worlds folders (Fantasty, Easter, etc.)
    for i, v in ipairs(game:GetService("ReplicatedStorage")["__DIRECTORY"].Eggs:GetChildren()) do
        -- Loop over Eggs in folder (Cracked Egg, etc.) (ie = index, ve = value / egg's name)
        for ie, ve in ipairs(v:GetChildren()) do
            -- Find moduleScript for current egg name (ve)
            local mod = ve:FindFirstChildOfClass("ModuleScript")
            -- If we find the associated moduleScript, add it to eggsData
            if mod then
                local eggInfo = require(mod)
                if eggInfo.hatchable and not eggInfo.disabled then
                    -- ve.Name = Egg name for buy egg invoke.
                    -- eggInfo.displayName = Name to match with dispenser / area
                    eggsData[ve.Name] = eggInfo
                end
            end
        end
    end
    return eggsData
end

function Util.GetEggNamesList(eggsData)
    local eggNamesList = {}
    for eggName, _ in pairs(eggsData) do
        table.insert(eggNamesList, eggName)
    end
    return eggNamesList
end

-- Get all areas
function Util.GetAreas()
    local tmpAreas = {}
    local worlds = game:GetService("ReplicatedStorage")["__DIRECTORY"].Areas:GetChildren()
    -- Loop over worlds folders (Fantasty, Easter, etc.)
    for i, v in ipairs(worlds) do
        -- Loop over areas in the current world folder
        for ie, ve in pairs(require(v)) do
            table.insert(tmpAreas, ie .. " | " .. v.Name)
        end
    end
    table.sort(tmpAreas, function(a, b)
        return a < b
    end)
    return tmpAreas
end

-- Get a list of area names for gui
function Util.GetAreaNames(areaMap)
    local areaNames = {}
    for _, areaWorldName in pairs(areaMap) do
        local areaName = Util.GetAreaBeforePipe(areaWorldName)
        table.insert(areaNames, areaName)
    end
    return areaNames
end

function Util.GetAreaBeforePipe(areaString)
    local splitString = {}
    for word in string.gmatch(areaString, "([^|]+)") do
        table.insert(splitString, word)
    end
    return splitString[1]:gsub("^%s*(.-)%s*$", "%1") -- Remove leading and trailing spaces
end

function Util.GetMyPets()
    return Lib.PetCmds.GetEquipped()
end

--returns all coins within the given area (area must be a table of conent)
function Util.GetCoins(area)
    local returntable = {}
    local listCoins = Invoke("Get Coins")
    -- print("getting coins in area: " .. area .. "")
    for i,v in pairs(listCoins) do
        if area == v.a then
            -- print("Found coin in area: " .. area .. " with index: " .. i .. "")
            local coin = v
            coin["index"] = i
            table.insert(returntable, coin)
        end
    end
    return returntable
end

function Util.FarmCoin(CoinID, PetID)
    print("farming coin (FarmCoin)")
    Invoke("Join Coin", CoinID, {PetID})
    Fire("Farm Coin", CoinID, PetID)
end

function Util.AutoFarm()
    if getgenv().Toggles.AutoFarmEnabledToggle.Value then
        Util.notify("Auto farm enabled")
        local CurrentFarmingPets = {}
        task.spawn(function()
            while getgenv().Toggles.AutoFarmEnabledToggle.Value do
                print("Getting equipped pets")
                local myPets = Util.GetMyPets()
                if getgenv().Options.FarmTypeDropdown.Value == "Normal" then
                    -- Normal farm
                    print("looking for coins in: " .. getgenv().Options.FarmAreaDropdown.Value)
                    local coins = Util.GetCoins(getgenv().Options.FarmAreaDropdown.Value)
                    for i = 1, #coins do
                        if getgenv().Toggles.AutoFarmEnabledToggle.Value and game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[i].index) then
                            print("Found child coin, idx: " ..coins[i].index)
                            for _, pet in pairs(myPets) do
                                print("pet loop, idx: " .. tostring(_))
                                task.spawn(function()
                                    Util.FarmCoin(coins[i].index, pet.uid)
                                end)
                            end
                        end
                        repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[i].index)
                    end
                elseif getgenv().Options.FarmTypeDropdown.Value == "Nearest" then
                    -- Farm nearest coins
                    -- WE SHOULD TRY NEAREST METHOD FROM HUGE GAMES INSTEAD.
                    local NearestOne = nil
                    local NearestDistance = math.huge
                    for i,v in pairs(game:GetService("Workspace")["__THINGS"].Coins:GetChildren()) do
                        task.wait(0.1)
                        if (v.POS.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < NearestDistance then
                            NearestOne = v
                            NearestDistance = (v.POS.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        end
                    end
                    for _, pet in pairs(myPets) do
                        task.wait(0.1)
                        task.spawn(function()
                            Util.FarmCoin(NearestOne.Name, pet.uid)
                            repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(NearestOne)
                        end)
                    end
                elseif getgenv().Options.FarmTypeDropdown.Value == "Multi Target" then
                    -- Multi target farm
                    print("looking for coins in: " .. getgenv().Options.FarmAreaDropdown.Value)
                    local coins = Util.GetCoins(getgenv().Options.FarmAreaDropdown.Value)
                    local Things = game:GetService("Workspace")["__THINGS"]
                    local Coins = Things.Coins
                    local Pets = Things.Pets
                    local numPets = #myPets
                    for i = 1, #coins do
                        local petIndex = i % numPets + 1
                        if i % numPets == numPets - 1 then
                            task.wait()
                        end
                        if not CurrentFarmingPets[myPets[petIndex]] then
                            task.spawn(function()
                                local currentPet = myPets[petIndex]
                                local currentCoin = coins[i].index
                                CurrentFarmingPets[currentPet] = 'Farming'
                                Util.FarmCoin(currentCoin, currentPet.uid)
                                repeat task.wait() until not Coins:FindFirstChild(currentCoin) or #Pets:GetChildren() == 0
                                CurrentFarmingPets[currentPet] = nil
                            end)
                        end
                        -- We get kicked if we farm to fast I think. trying to slow it down with this. task.wait(0.2) confirmed no kick.
                        task.wait(0.15)
                    end
                elseif getgenv().Options.FarmTypeDropdown.Value == "Highest Value" then
                    -- Farm highest value coin
                    local coins = Util.GetCoins(getgenv().Options.FarmAreaDropdown.Value)
                    for _, pet in pairs(myPets) do
                        task.spawn(function() task.wait() Util.FarmCoin(coins[1].index, pet.uid) end)
                    end
                    repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[1].index) or #game:GetService("Workspace")["__THINGS"].Pets:GetChildren() == 0
                end
            end
        end)
    else
        Util.notify("Auto farm disabled")
    end
end

-- Similar to GetCoins but for comets
function Util.GetComets(area)
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

function Util.HopToNewServer()
    local Servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/6284583030/servers/Public?sortOrder=Asc&limit=100"))
    for i,v in pairs(Servers.data) do
      if v.playing ~= v.maxPlayers then
        print("teleporting to server: ", v.id)
        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, v.id)
        repeat task.wait() until game.JobId == v.id and game:IsLoaded()
      end
    end
end

-- Find comets in the server
function Util.GetCometData()
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

function Util.TeleportToArea(area)
    task.spawn(function()
        task.wait(0.1)
        set_thread_identity(2)
        tp.Teleport(area)
    end)
end

function Util.AutoCometFarm()
    if getgenv().Toggles.AutoCometFarmEnabledToggle.Value then
        print("Auto comet farm enabled!")
        task.spawn(function()
           while getgenv().Toggles.AutoCometFarmEnabledToggle.Value do
            local comets = Util.GetCometData()
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
                            Util.TeleportToArea(cometArea)
                            -- get coin data for area
                            local cometCoinObjects = Util.GetComets(cometArea)
                            local myPets = Util.GetMyPets()
                            for i = 1, #cometCoinObjects do
                                if getgenv().Toggles.AutoFarmEnabledToggle.Value and game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index) then
                                    print("Found child coin, idx: " ..cometCoinObjects[i].index)
                                    for _, pet in pairs(myPets) do
                                        print("pet loop, idx: " .. tostring(_))
                                        task.spawn(function()
                                            Util.FarmCoin(cometCoinObjects[i].index, pet.uid)
                                        end)
                                    end
                                end
                                repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(cometCoinObjects[i].index)
                            end
                        else
                            print("Comet already destroyed.")
                        end
                    end
                else
                    print("No comet found.")
                    Util.HopToNewServer()
                end
            end
           end
        end)
    end
end

-- Returns the CFrame of the Egg Dispenser
function Util.GetEggDispenserLocation(eggAreaName)
    local eggs = game:GetService("Workspace")["__MAP"].Eggs

    for _, eggArea in pairs(eggs:GetChildren()) do
        local eggAreaString = tostring(eggArea)
        if string.find(eggAreaString, eggAreaName) then
            print("Found egg area: " .. eggAreaString)
            local eggsFolder = eggArea:FindFirstChild("Eggs")
            if eggsFolder then
                for _, eggCapsule in ipairs(eggsFolder:GetChildren()) do
                    if eggCapsule.Name == "Egg Capsule" then
                        local eggObject = eggCapsule:FindFirstChild("Egg")
                        if eggObject then
                            print("Egg object found: " .. eggObject.Name)
                            print("Egg object CFrame: " .. tostring(eggObject.CFrame))
                            return eggObject.CFrame
                        end
                    end
                end
            end
        end
    end
end

function Util.TeleportToEggDispenser(eggAreaName)
    print("Calling GetEggDispenserLocation with area: " .. eggAreaName)
    local eggDispenserLocation = Util.GetEggDispenserLocation(eggAreaName)
    -- Slight offset otherwise we'll teleport inside the object and won't be able to move.
    local offset = Vector3.new(0, 0, 5)
    local teleportLocation = eggDispenserLocation + offset
    -- print("Teleporting to egg dispenser location: " .. tostring(teleportLocation))
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleportLocation
    task.wait(2)
end

function Util.AutoHatch()
    if getgenv().Toggles.AutoHatchEnabledToggle.Value then
        Util.notify("Auto hatch enabled")
        Util.notify("Egg choice: " .. tostring(getgenv().Options.AutoHatchEggChoiceDropdown.Value))
        task.spawn(function()
            local eggsData = Util.GetEggData()
            local chosenEggName = tostring(getgenv().Options.AutoHatchEggChoiceDropdown.Value)
            local chosenEgg = eggsData[chosenEggName]
            local chosenEggArea = chosenEgg.area
            local allPets = Lib.Save.Get().Pets
            -- Teleporting to world if needed
            print("Teleporting to: " .. chosenEggArea)
            Util.TeleportToArea(chosenEggArea)
            task.wait(5)
            print("Moving character to egg dispenser: " .. chosenEggArea)
            Util.TeleportToEggDispenser(chosenEggArea)
            while getgenv().Toggles.AutoHatchEnabledToggle.Value do
                Util.notify("Hatching egg: " .. chosenEggName)
                Invoke("Buy Egg", chosenEggName, getgenv().Toggles.EnableTripleHatchToggle.Value, getgenv().Toggles.EnableOctupleHatchToggle.Value)
                task.wait(1.5)
            end
        end)
    end
end

function Util.SkipEggAnimation()
    if getgenv().Toggles.SkipEggAnimationToggle.Value then
        game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Game["Open Eggs"].Disabled = true
    else
        game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Game["Open Eggs"].Disabled = false
    end
end

function Util.CollectFreeGifts()
    if getgenv().Toggles.AutoCollectFreeGiftsToggle.Value then
        Util.notify("Auto collect gifts enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoCollectFreeGiftsToggle.Value do
                print("Checking for free gifts...")
                local txt = game:GetService("Players").LocalPlayer.PlayerGui.FreeGiftsTop.Button.Timer.Text
                if txt == "Ready!" then
                    Util.notify("Collecting gifts...")
                    for i = 1,12 do
                        print("Collecting gift number: " .. i)
                        Invoke("Redeem Free Gift", i)
                        task.wait(1.2)
                    end
                else
                    print("Free gifts aren't ready to collect...")
                    task.wait(60)
                end
            end
        end)
    else
        Util.notify("Auto collect gifts disabled")
    end
end

function Util.CollectRankRewards()
    if getgenv().Toggles.AutoCollectRankRewardsToggle.Value then
        Util.notify("Auto collect rank rewards enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoCollectRankRewardsToggle.Value do
                Save = Lib.Save.Get()
                rankCooldown = Lib.Directory.Ranks[Save.Rank].rewardCooldown
                if ((Save["RankTimer"] + rankCooldown) < os.time()) then
                    Util.notify("collecting rank rewards...")
                    Invoke("collect Rank Rewards")
                    task.wait(2)
                else
                    print("Rank rewards not available...")
                    task.wait(60)
                end
            end
        end)
    else
        Util.notify("Auto redeem rank rewards disabled")
    end
end

function Util.AutoTripleCoins()
    if getgenv().Toggles.AutoTripleCoinsToggle.Value then
        Util.notify("Auto triple coins enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoTripleCoinsToggle.Value do
                -- activate triple coins "potion" if not already active
                local Save = Lib.Save.Get()
                if Save["Boosts"]["Triple Coins"] == nil or Save["Boosts"]["Triple Coins"] < 60 then
                    Util.notify("Activating triple coins")
                    Fire("Activate Boost", "Triple Coins")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto triple coins disabled")
    end
end

function Util.AutoTripleDamage()
    if getgenv().Toggles.AutoTripleDamageToggle.Value then
        Util.notify("Auto triple damage enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoTripleDamageToggle.Value do
                -- activate triple damage "potion" if not already active
                local Save = Lib.Save.Get()
                if Save["Boosts"]["Triple Damage"] == nil or Save["Boosts"]["Triple Damage"] < 60 then
                    Util.notify("Activating triple damage")
                    Fire("Activate Boost", "Triple Damage")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto triple damage disabled")
    end
end

function Util.AutoSuperLucky()
    if getgenv().Toggles.AutoSuperLuckyToggle.Value then
        Util.notify("Auto super lucky enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoSuperLuckyToggle.Value do
                -- activate super lucky "potion" if not already active
                local Save = Lib.Save.Get()
                if Save["Boosts"]["Super Lucky"] == nil or Save["Boosts"]["Super Lucky"] < 60 then
                    Util.notify("Activating super lucky")
                    Fire("Activate Boost", "Super Lucky")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto super lucky disabled")
    end
end

function Util.AutoUltraLucky()
    if getgenv().Toggles.AutoUltraLuckyToggle.Value then
        Util.notify("Auto ultra lucky enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoUltraLuckyToggle.Value do
                -- activate ultra lucky "potion" if not already active
                local Save = Lib.Save.Get()
                if Save["Boosts"]["Ultra Lucky"] == nil or Save["Boosts"]["Ultra Lucky"] < 60 then
                    Util.notify("Activating ultra lucky")
                    Fire("Activate Boost", "Ultra Lucky")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto ultra lucky disabled")
    end
end

function Util.GetServerBoostData()
    local activeBoostsData = {}
    local activeBoosts = Lib.ServerBoosts.GetActiveBoosts()

    -- Names are in order: "Insane Luck table", "Triple Coins table", "Super Lucky table", "Triple Damage table"
    for boostName, boostTable in pairs(activeBoosts) do
        -- print("Boost name: " ..boostName)
        -- print("Boost table: " ..tostring(boostTable))
        for _, timeRemaining in pairs(boostTable) do
            print(timeRemaining)
            activeBoostsData[boostName] = timeRemaining
        end
    end
    return activeBoostsData
end

function Util.UseServerBoost(boostName)
    print("Using server boost: " .. boostName)
    Fire("Activate Server Boost", boostName)
end

function Util.AutoServerTripleCoins()
    if getgenv().Toggles.AutoServerTripleCoinsToggle.Value then
        Util.notify("Auto server triple coins enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoServerTripleCoinsToggle.Value do
                local serverBoostData = Util.GetServerBoostData()
                if not serverBoostData["Triple Coins"] or serverBoostData["Triple Coins"] < 60 then
                    Util.notify("Activating server triple coins")
                    Util.UseServerBoost("Triple Coins")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto server triple coins disabled")
    end
end

function Util.AutoServerTripleDamage()
    if getgenv().Toggles.AutoServerTripleDamageToggle.Value then
        Util.notify("Auto server triple damage enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoServerTripleDamageToggle.Value do
                local serverBoostData = Util.GetServerBoostData()
                if not serverBoostData["Triple Damage"] or serverBoostData["Triple Damage"] < 60 then
                    Util.notify("Activating server triple damage")
                    Util.UseServerBoost("Triple Damage")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto server triple damage disabled")
    end
end

function Util.AutoServerSuperLucky()
    if getgenv().Toggles.AutoServerSuperLuckyToggle.Value then
        Util.notify("Auto server super lucky enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoServerSuperLuckyToggle.Value do
                local serverBoostData = Util.GetServerBoostData()
                if not serverBoostData["Super Lucky"] or serverBoostData["Super Lucky"] < 60 then
                    Util.notify("Activating server super lucky")
                    Util.UseServerBoost("Super Lucky")
                    task.wait(5)
                end
                task.wait(5)
            end
        end)
    else
        Util.notify("Auto server super lucky disabled")
    end
end

function Util.UnlockGamepasses()
    Util.notify("Unlocking gamepasses")
    task.spawn(function()
        if getgenv().Toggles.UnlockGamepassesToggle then
            Lib.Gamepasses.Owns = function() return true end
            local teleportScript = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
            if teleportScript.UpdateAreas then
                teleportScript.UpdateAreas()
                teleportScript.UpdateBottom()
            end
        else
            Lib.Gamepasses.Owns = function(p1, p2)
                if not p2 then
                    p2 = game:GetService("Players").LocalPlayer;
                end;
                v2 = Lib.Save.Get();
                if not v2 then
                    return;
                end;
                l__Gamepasses__3 = v2.Gamepasses;
                for v4, v5 in pairs(v2.Gamepasses) do
                    if tostring(v5) == tostring(p1) then
                        return true;
                    end;
                end;
                return false;
            end;
            local teleportScript = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
            teleportScript.UpdateAreas()
            teleportScript.UpdateBottom()
            -- This doesn't seem to work anymore but can't easily see why. Path looks correct and I see calls to UpdateButton. No errors in either console.
            -- Unlock gamepasses in Huge Games doesn't seem to unlock hoverboard either.
            local hover = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Game.Hoverboard)
            hover.UpdateButton()
        end
    end)
end

function Util.AutoCollectOrbs()
    if getgenv().Toggles.AutoCollectOrbsToggle.Value then
        Util.notify("Auto orbs enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoCollectOrbsToggle.Value do
                local orbs = game:GetService("Workspace")["__THINGS"]:FindFirstChild("Orbs")
                for i,v in pairs(orbs:GetChildren()) do
                    v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                end
                task.wait(1)
            end
        end)
    else
        Util.notify("Auto orbs disabled")
    end
end

function Util.AntiAfk()
    if getgenv().Toggles.AntiAfkToggle.Value then
        Util.notify("Anti afk enabled")
        for i,v in pairs(getconnections(game:GetService('Players').LocalPlayer.Idled)) do
            v:Disable()
        end
    else
        for i,v in pairs(getconnections(game:GetService('Players').LocalPlayer.Idled)) do
            v:Enable()
        end
        Util.notify("Anti afk disabled")
    end
end

function Util.FriendAllPlayers()
    task.spawn(function()
        print("Sending friend request to all players")
        for _,z in pairs(game.Players:GetChildren()) do game.Players.LocalPlayer:RequestFriendship(z) end
    end)
end

-- Unlock hacker portal function
function Util.unlockHackerPortal()
    -- Start hacker portal quest
    print("Unlocking hacker portal")
    print("Starting hacker portal quest")
    Invoke("Start Hacker Portal Quest")

    -- Need to break 3 hacker portal chests after starting
    print("Breaking 3 hacker portal chests")
    -- Not really sure the best way to do this.
    -- Teleport to Hacker Portal then run farm functions to break 3 chests I guess.

    -- Fire events to finish hacker portal quest
    print("Finishing hacker portal quest")
    Invoke("Finish Hacker Portal Quest")
    Fire("Hacker Portal Unlocked")
end

-- Auto collect lootbags
function Util.AutoCollectLootbags()
    if getgenv().Toggles.AutoCollectLootbagsToggle.Value then
        Util.notify("Auto lootbags enabled")
        task.spawn(function()
            while getgenv().Toggles.AutoCollectLootbagsToggle.Value do
                local lootbags = game:GetService("Workspace")["__THINGS"]:FindFirstChild("Lootbags")
                for i,v in pairs(lootbags:GetChildren()) do
                    v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                    task.wait(0.1)
                end
                task.wait(1)
            end
        end)
    else
        Util.notify("Auto lootbags disabled")
    end
end

function Util.GetCoinsAmount(coinName)
    local coinAmount = string.gsub(menus[coinName].Amount.Text, ",", "")
    print("Returning " ..coinName .." amount: ", coinAmount)
    return coinAmount
end

function Util.EnableStatTrackMenus(coinName)
    menus.UIListLayout.HorizontalAlignment = 2
    local tempmaker = menus:WaitForChild(coinName):Clone()
    tempmaker.Name = tostring(tempmaker.Name .. "2")
    tempmaker.Parent = menus
    tempmaker.Size = UDim2.new(0, 175, 0, 30)
    tempmaker.LayoutOrder = tempmaker.LayoutOrder + 1
    _G.MyTypes[coinName] = tempmaker
end

-- EnableCoinStatTrack
function Util.EnableCoinStatTrack(coinName)
    if getgenv().Toggles.EnableCoinStatTrackToggle.Value then
        Util.notify("Stat tracking coin: " ..getgenv().Options.StatTrackCoinTypeDropdown.Value)
        -- Initialize an empty queue data structure
        local coinQueue = {}
        _G.MyTypes = {}
        local Commas = Lib.Functions.Commas
        Util.EnableStatTrackMenus(coinName)
        task.spawn(function()
            while getgenv().Toggles.EnableCoinStatTrackToggle.Value do
                -- Get starting coin amount
                local previousCoins = Util.GetCoinsAmount(coinName)
                print("Previous coins: ", previousCoins)

                while true do
                -- Get current coin amount
                local currentCoins = Util.GetCoinsAmount(coinName)

                -- Add the current coin amount to the end of the queue
                table.insert(coinQueue, currentCoins - previousCoins)
                previousCoins = currentCoins

                -- If the queue has more than 60 elements, remove the oldest one
                if #coinQueue > 60 then
                    table.remove(coinQueue, 1)
                end

                -- Calculate and print the average coins gained per minute
                local totalGain = 0
                for i = 1, #coinQueue do
                    totalGain = totalGain + coinQueue[i]
                end
                local averageGainPerMinute = totalGain / #coinQueue * 60
                print("Estimated coins gained per minute: ", averageGainPerMinute)
                _G.MyTypes[coinName].Amount.Text = tostring(Commas(averageGainPerMinute).." in 60s")
                _G.MyTypes[coinName].Amount_odometerGUIFX.Text = tostring(Commas(averageGainPerMinute).." in 60s")

                -- Wait for 1 second before the next iteration
                task.wait(1)
                end
            end
        end)
    end
end

-- Set low fps
function Util.SetFps(fpsValue)
    if getgenv().Toggles.LowFPSToggle.Value then
        Util.notify("Low fps enabled")
        setfpscap(fpsValue)
    else
        Util.notify("Low fps disabled")
        setfpscap(240)
    end
end

-- Disable Graphics Rendering
function Util.SetGraphicsRendering()
    if getgenv().Toggles.DisableGraphicsRenderingToggle.Value then
        Util.notify("Graphics rendering disabled")
        RunService:Set3dRenderingEnabled(false)
    else
        Util.notify("Graphics rendering enabled")
        RunService:Set3dRenderingEnabled(true)
    end
end

function Util.GetBankName(ownerID)
    local Players = game:GetService("Players")
    local name = Players:GetNameFromUserIdAsync(ownerID)
    return name
end

function Util.GetBankNames()
    local myBanks = Invoke("Get My Banks")
    local bankNames = {}
    for i,v in pairs(myBanks) do
        local ownerName = Util.GetBankName(v.Owner)
        table.insert(bankNames, ownerName)
    end
    return bankNames
end

function Util.DepositFiftyPets(bankOwnerName)
    local myBanks = Invoke("Get My Banks")
    for i,v in pairs(myBanks) do
        local ownerName = Util.GetBankName(v.Owner)
        if ownerName == bankOwnerName then
            local bankID = v.BUID
            local petsToDeposit = {}
            local pets = Lib.Save.Get().Pets

            print("Found matching bank with name: " ..ownerName .." and BUID: " ..bankID)

            for i2,v2 in pairs(pets) do
                if i2 < 51 then
                    table.insert(petsToDeposit, v2.uid)
                else
                    break
                end
            end
            -- Need to have at least one pet in our inventory.
            table.remove(petsToDeposit, #petsToDeposit)

            print("Depositing " ..tostring(#petsToDeposit) .." pets into bank owned by " ..ownerName)
            Invoke("Bank Deposit", bankID, petsToDeposit, 0)
            break
        end
    end
end

function Util.WithdrawFiftyPets(bankOwnerName)
    local myBanks = Invoke("Get My Banks")
    for i,v in pairs(myBanks) do
        local ownerName = Util.GetBankName(v.Owner)
        if ownerName == bankOwnerName then
            local petsToWithdraw = {}
            local bankID = v.BUID
            local bank = Invoke("Get Bank", bankID)
            local bankPets = bank["Storage"]["Pets"]

            print("Found matching bank with name: " ..ownerName .." and BUID: " ..bankID)

            for i2,v2 in pairs(bankPets) do
                if i2 < 51 then
                    table.insert(petsToWithdraw, v2.uid)
                else
                    break
                end
            end

            print("Withdrawing " ..tostring(#petsToWithdraw) .." pets from bank owned by " ..ownerName)
            Invoke("Bank Withdraw", bankID, petsToWithdraw, 0)
            break
        end
    end
end

-- UpgradePetsToGold
function Util.UpgradePetsToGold(petLookupTable)
    Util.notify("Upgrading pets to gold")
    if not petLookupTable then
        print("We weren't provided a lookup table. building a new one.")
        petLookupTable = Util.BuildPetDataLookupTable()
    end
    local pets = Lib.Save.Get().Pets
    local petsToUpgrade = {}
    local petUIDs = {} -- create a new table to store the pet's uids
    for i,pet in pairs(pets) do
        task.wait(0.1)
        local petID = pet["id"]
        local petData = petLookupTable[petID]
        local petName = petData.name
        local fullPetName = Util.GetFullPetName(pet, petName) -- This is what makes it check for golden, rainbow, dark matter, etc.
        -- Check that fullPetName doesn't contain "Golden", "Rainbow", or "Dark Matter"
        if not string.find(fullPetName, "Golden") and not string.find(fullPetName, "Rainbow") and not string.find(fullPetName, "Dark Matter") then
            -- Add 1 to counter for that pet name
            if not petsToUpgrade[fullPetName] then
                petsToUpgrade[fullPetName] = 1
                petUIDs[fullPetName] = {pet.uid} -- store the pet's uid in a list
            else
                petsToUpgrade[fullPetName] = petsToUpgrade[fullPetName] + 1
                table.insert(petUIDs[fullPetName], pet.uid) -- add the pet's uid to the list
            end
            -- Check if the counter for that pet is at 6
            if petsToUpgrade[fullPetName] == 6 then
                Invoke("Use Golden Machine", petUIDs[fullPetName])
                task.wait(1)

                -- Reset the counter and the uid list for that pet
                petsToUpgrade[fullPetName] = nil
                petUIDs[fullPetName] = nil
            end
        end
    end
    print("Finished upgrading pets to gold.")
end

-- Upgrade pets to rainbow
function Util.UpgradePetsToRainbow(petLookupTable)
    Util.notify("Upgrading pets to rainbow")
    if not petLookupTable then
        print("We weren't provided a lookup table. building a new one.")
        petLookupTable = Util.BuildPetDataLookupTable()
    end
    local pets = Lib.Save.Get().Pets
    local petsToUpgrade = {}
    local petUIDs = {} -- create a new table to store the pet's uids
    for i,pet in pairs(pets) do
        task.wait(0.1)
        local petID = pet["id"]
        local petData = petLookupTable[petID]
        local petName = petData.name
        local fullPetName = Util.GetFullPetName(pet, petName) -- This is what makes it check for golden, rainbow, dark matter, etc.
        -- Check that fullPetName contains "Golden"
        if string.find(fullPetName, "Golden") then
            -- Add 1 to counter for that pet name
            if not petsToUpgrade[fullPetName] then
                petsToUpgrade[fullPetName] = 1
                petUIDs[fullPetName] = {pet.uid} -- store the pet's uid in a list
            else
                petsToUpgrade[fullPetName] = petsToUpgrade[fullPetName] + 1
                table.insert(petUIDs[fullPetName], pet.uid) -- add the pet's uid to the list
            end
            -- Check if the counter for that pet is at 6
            if petsToUpgrade[fullPetName] == 6 then
                Invoke("Use Rainbow Machine", petUIDs[fullPetName])
                task.wait(1)

                -- Reset the counter and the uid list for that pet
                petsToUpgrade[fullPetName] = nil
                petUIDs[fullPetName] = nil
            end
        end
    end
    print("Finished upgrading pets to rainbow.")
end

-- Get pet's type (basic, gold, rainbow, dark matter)
function Util.GetFullPetName(petData, petName)
    local fullName = petName
    pcall(function()
        if petData.g then fullName = "Golden " .. fullName end
    end)
    pcall(function()
        if petData.r then fullName = "Rainbow " .. fullName end
    end)
    pcall(function()
        if petData.dm then fullName = "Dark Matter " .. fullName end
    end)
    return fullName
end

-- Can map a pet id to pet data held in ReplicatedStorage.__DIRECTORY.Pets. Mostly used for pet rarity.
function Util.BuildPetDataLookupTable()
    print("Building pet data lookup table")
    local petLookupTable = {}
    local pets = game:GetService("ReplicatedStorage")["__DIRECTORY"].Pets:GetChildren()

    for _, pet in pairs(pets) do
        local petID = string.match(pet.Name, "%d+")
        for _, child in pairs(pet:GetChildren()) do
            if child:IsA("ModuleScript") then
                if not petLookupTable[petID] then
                    petLookupTable[petID] = require(child)
                end
                break
            end
        end
    end
    return petLookupTable
end

-- Deletes all duplicate pets in inventory.
function Util.DeleteDuplicatePets(petLookupTable)
    local uniquePets = {}
    local petsToDelete = {}
    local allPets = Lib.Save.Get().Pets

    if not petLookupTable then
        print("We weren't provided a lookup table. building a new one.")
        petLookupTable = Util.BuildPetDataLookupTable()
    end

    for _, pet in pairs(allPets) do
        task.wait(0.1)
        local petID = pet["id"]
        local petData = petLookupTable[petID]
        local petName = petData.name
        local fullPetName = Util.GetFullPetName(pet, petName) -- This is what makes it check for golden, rainbow, dark matter, etc.

        -- print("Checking pet: " .. fullPetName)

        if uniquePets[fullPetName] then
            -- This pet is a duplicate, mark it for deletion
            print("Adding duplicate pet to deletion table: " .. fullPetName)
            table.insert(petsToDelete, pet.uid)
        else
            -- This pet is unique, add it to the uniquePets table
            uniquePets[fullPetName] = true
        end
    end

    -- Now delete all the duplicate pets
    local duplicatePetCount = #petsToDelete
    if duplicatePetCount > 0 then
        print("Deleting " ..duplicatePetCount .." duplicate pets")
        Invoke("Delete Several Pets", petsToDelete)
    end
end

-- Delete pets in inventory if it's a duplicate
function Util.AutoDeleteDuplicatePets(lookupTable)
    task.spawn(function()
        if getgenv().Toggles.AutoDeleteDuplicatePetsToggle.Value then
            Util.notify("Deleting duplicate pets enabled")
            while getgenv().Toggles.AutoDeleteDuplicatePetsToggle.Value do
                task.wait(1)
                Util.DeleteDuplicatePets(lookupTable)
            end
        else
            Util.notify("Auto delete duplicate pets disabled")
        end
    end)
end

return Util