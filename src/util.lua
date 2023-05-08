---@diagnostic disable: undefined-global

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
                    for i = 1, #coins do
                        if i%#myPets == #myPets-1 then
                            task.wait()
                        end
                        if not CurrentFarmingPets[myPets[i%#myPets+1]] or CurrentFarmingPets[myPets[i%#myPets+1]] == nil then
                            task.wait(0.1)
                            task.spawn(function()
                                CurrentFarmingPets[myPets[i%#myPets+1]] = 'Farming'
                                Util.FarmCoin(coins[i].index, myPets[i%#myPets+1].uid)
                                repeat task.wait() until not game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[i].index) or #game:GetService("Workspace")["__THINGS"].Pets:GetChildren() == 0
                                CurrentFarmingPets[myPets[i%#myPets+1]] = nil
                            end)
                        end
                    end
                elseif getgenv().Options.FarmTypeDropdown.Value == "Highest Value" then
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
            -- Teleporting to world if needed
            set_thread_identity(2)
            print("Teleporting to: " .. chosenEggArea)
            tp.Teleport(chosenEggArea)
            task.wait(10)
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
            teleportScript.UpdateAreas()
            teleportScript.UpdateBottom()
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

return Util