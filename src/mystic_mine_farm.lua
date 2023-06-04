---@diagnostic disable: undefined-global

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local tp = getsenv(localPlayer.PlayerScripts.Scripts.GUIs.Teleport)

local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
while not Lib.Loaded do
    RunService.Heartbeat:Wait()
end

local Network = require(ReplicatedStorage.Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

-- Hook Fire/Invoke to bypass AC
local old = hookfunction(getupvalue(Fire, 1), function(...)
    return true
end)

-- Variables
local FARM_FRUIT = true
local MINIMUM_ORANGES = 100

getgenv().webhookUrl = "https://discord.com/api/webhooks/960237304709013655/5icfh1TwM0pZEGNu2kclhInIYh7WhQ_BeIs5TLDvs4cGmOjHHE5boLFqk69ozGJUqxn_"
getgenv().mailRecipient = "gavinnn1000"

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
    -- print("getting coins in area: " .. area .. "")
    for i,v in pairs(listCoins) do
        -- for i2,v2 in pairs(v) do
        --     print(i2,v2)
        -- end
        if area == v.a then
            -- print("Found coin in area: " .. area .. " with index: " .. i .. "")
            local coin = v
            coin["index"] = i
            table.insert(coinTable, coin)
        end
    end
    return coinTable
end

function farmMysticMine()
    local selectedAreas = {"Mystic Mine"}
    print("Getting equipped pets")
    local myPets = GetMyPets()
    for _,selectedArea in ipairs(selectedAreas) do  -- Iterate through each selected area
        task.wait(0.1)
        print("Looking for coins in area: " .. selectedArea)
        local coins = GetCoins(selectedArea)
        -- print length of coins
        print("Found " .. #coins .. " coins in area: " .. selectedArea .. "")

        for i = 1, #coins do
            if Workspace["__THINGS"].Coins:FindFirstChild(coins[i].index) then
                print("Found child coin, idx: " .. coins[i].index)
        
                for _, pet in pairs(myPets) do
                    print("Pet loop, idx: " .. tostring(_))
                    task.spawn(function()
                        FarmCoin(coins[i].index, pet.uid)
                    end)
                end
            end
            print("Waiting for coin to break (idx: " .. coins[i].index .. ")")
        
            local startTime = os.time()  -- Record the start time
            repeat
                task.wait()
            until not Workspace["__THINGS"].Coins:FindFirstChild(coins[i].index) or os.time() - startTime >= 30
        
            if Workspace["__THINGS"].Coins:FindFirstChild(coins[i].index) then
                print("Coin still exists after timeout (idx: " .. coins[i].index .. ")")
            else
                print("Coin broken (idx: " .. coins[i].index .. ")")
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
                v.CFrame = localPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end)
end

function AutoCollectOrbs()
    task.spawn(function()
        while task.wait(0.1) and game:IsLoaded() do
            local orbs = GetOrbs()
            for _, v in ipairs(orbs) do
                v.CFrame = localPlayer.Character.HumanoidRootPart.CFrame
            end
        end
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
function CreatePlatform()
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart

        local platform = workspace:FindFirstChild("Platformm")
        if not platform then
            -- Create the platform if it doesn't exist
            platform = Instance.new("Part")
            platform.Name = "Platformm"
            platform.Parent = workspace
            platform.Anchored = true
            platform.Size = Vector3.new(100, 1, 100)
            platform.BrickColor = BrickColor.new("Baby blue")
            platform.Transparency = 0.3
        end

        -- Move the platform to a position 2 units under the player
        platform.Position = rootPart.Position + Vector3.new(0, -50, 0)
    end
end

-- Function to teleport the player to the platform
function TeleportToPlatform()
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart

        local platform = workspace:FindFirstChild("Platformm")
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

-- Mail all gems to getgenv().mailRecipient
function MailDiamonds()
    local mailboxCFrame = CFrame.new(254.149002, 98.2168579, 349.55304, 0.965907216, -6.73597569e-08, -0.258888513, 6.48122409e-08, 1, -1.83752729e-08, 0.258888513, 9.69664127e-10, 0.965907216)
    local localPlayerName = localPlayer.Name
    local mailRecipient = getgenv().mailRecipient
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
    print("Sending webhook to alert that we mailed our gems.")
    webhook(localPlayerName, mailRecipient, gemsToSend)
end

function main()
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

    -- Teleport to farm area.
    TeleportToArea("Mystic Mine")
    -- Move character to center of mine area
    teleportToCenterOfMine()
    -- Create a platform to hide on
    CreatePlatform()

    -- Farm loop
    while true do
        -- Mail diamonds if needed while theres no comet to farm.
        local diamonds = GetPlayerCash("Diamonds")
        if tonumber(diamonds) > 100000000000 then
            MailDiamonds()
        end
        if FARM_FRUIT and getOrangeCount() < MINIMUM_ORANGES - 10 then -- -10 so we arent constantly swapping between farming fruits and diamonds.
            TeleportToArea("Pixel Vault")
            while getOrangeCount() < MINIMUM_ORANGES do
                print("Farming oranges... Current count: " .. getOrangeCount() .. " total needed: " .. MINIMUM_ORANGES)
                farmOranges()
            end
        end
        -- Teleport to platform
        TeleportToPlatform()
        -- Farm mystic mine if we dont need to farm fruit.
        farmMysticMine()
    end
end

main()
