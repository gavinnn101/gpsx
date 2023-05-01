---@diagnostic disable: undefined-global

function loadScript(arg)
    -- Wait for game to load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
    while not Lib.Loaded do
        game:GetService("RunService").Heartbeat:Wait()
    end

    Util.bypassAC()

    -- Main script functionality
    local group = arg
    getgenv().settings = Util.loadSettings(group)
    local HttpService = game:GetService('HttpService')

    -- Bypass environment check to allow use of invoke and fire
    -- https://v3rmillion.net/showthread.php?tid=1198487
    local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
    local Fire, Invoke = Network.Fire, Network.Invoke
    -- Hooking the _check function in the module to bypass the anticheat.
    -- local old
    -- old = hookfunction(getupvalue(Fire, 1), function(...)
    --    return true
    -- end)
    -- local Client = require(game.ReplicatedStorage.Library.Client)
    debug.setupvalue(Invoke, 1, function() return true end)
    debug.setupvalue(Fire, 1, function() return true end)

    Util.notify("Script loaded with settings: " .. group)

    -- Variables
    local allAreas = Util.getAreas()
    -- -- loop over allAreas and print them
    -- for i, v in pairs(allAreas) do
    --     for k, attr in pairs(v) do
    --         print(k .. ": " .. tostring(attr))
    --     end
    -- end

    local AreaMap = {
        --Misc
        ['VIP'] = {'VIP'};
        --Spawn
        ['Town'] = {'Town', 'Town FRONT'}; ['Forest'] = {'Forest', 'Forest FRONT'}; ['Beach'] = {'Beach', 'Beach FRONT'}; ['Mine'] = {'Mine', 'Mine FRONT'}; ['Winter'] = {'Winter', 'Winter FRONT'}; ['Glacier'] = {'Glacier', 'Glacier Lake'}; ['Desert'] = {'Desert', 'Desert FRONT'}; ['Volcano'] = {'Volcano', 'Volcano FRONT'};
        -- Fantasy init
        ['Enchanted Forest'] = {'Enchanted Forest', 'Enchanted Forest FRONT'}; ['Ancient'] = {'Ancient Island'}; ['Samurai'] = {'Samurai Island', 'Samurai Island FRONT'}; ['Candy'] = {'Candy Island'}; ['Haunted'] = {'Haunted Island', 'Haunted Island FRONT'}; ['Hell'] = {'Hell Island'}; ['Heaven'] = {'Heaven Island'};
        -- Tech
        ['Ice Tech'] = {'Ice Tech'}; ['Tech City'] = {'Tech City'; 'Tech City FRONT'}; ['Dark Tech'] = {'Dark Tech'; 'Dark Tech FRONT'}; ['Steampunk'] = {'Steampunk'; 'Steampunk FRONT'}, ['Alien Forest'] = {"Alien Forest"; "Alien Forest FRONT"}, ['Alien Lab'] = {"Alien Lab"; "Alien Lab FRONT"}, ['Glitch'] = {"Glitch"; "Glitch FRONT"}; ['Hacker Portal'] = {"Hacker Portal", "Hacker Portal FRONT"};
        -- Axolotl
        ['Axolotl Ocean'] = {'Axolotl Ocean', 'Axolotl Ocean FRONT'}; ['Axolotl Deep Ocean'] = {'Axolotl Deep Ocean', 'Axolotl Deep Ocean FRONT'}; ['Axolotl Cave'] = {'Axolotl Cave', 'Axolotl Cave FRONT'};
        -- Minecraft
        ['Pixel Forest'] = {'Pixel Forest', 'Pixel Forest FRONT'}; ['Pixel Kyoto'] = {'Pixel Kyoto', 'Pixel Kyoto FRONT'}; ['Pixel Alps'] = {'Pixel Alps', 'Pixel Alps FRONT'} ; ['Pixel Vault'] = {'Pixel Vault', 'Pixel Vault FRONT'};
    }

    --returns all coins within the given area (area must be a table of conent)
    function getCoins(area)
        local returntable = {}
        local listCoins = Invoke("Get Coins")
        for i,v in pairs(listCoins) do
            if area == 'All' or table.find(AreaMap[area], v.a) then
                local coin = v
                coin["index"] = i
                table.insert(returntable, coin)
            end
        end
        return returntable
    end

    function FarmCoin(CoinID, PetID)
        print("farming coin (FarmCoin)")
        Invoke("Join Coin", CoinID, {PetID})
        Fire("Farm Coin", CoinID, PetID)
    end

    -- Game automation functions linked to Rayfield GUI components in gpsx_ui.lua
    local actions = {
        -- auto farm
        startAutoFarm = function()
            if getgenv().settings.AutoFarm.auto_farm_enabled_toggle then
                Util.notify("Auto farm enabled")
                task.spawn(function()
                    while getgenv().settings.AutoFarm.auto_farm_enabled_toggle do
                        local myPets = Util.getMyPets()
                        if getgenv().settings.AutoFarm.farm_type_choice == "Normal" then
                            -- Normal farm
                            local coins = getCoins("Town")
                            for i = 1, #coins do
                                if getgenv().settings.AutoFarm.auto_farm_enabled_toggle and game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[i].index) then
                                    print("Found child coin, idx: " ..coins[i].index)
                                    for _, bb in pairs(myPets) do
                                        print("pet loop, idx: " .. tostring(_))
                                        if getgenv().settings.AutoFarm.auto_farm_enabled_toggle and game:GetService("Workspace")["__THINGS"].Coins:FindFirstChild(coins[i].index) then
                                            task.wait(2)
                                            print("calling FarmCoin")
                                            task.spawn(function()
                                                FarmCoin(coins[i].index, bb)
                                            end)
                                        end
                                    end
                                end
                            end
                        elseif getgenv().settings.AutoFarm.farm_type_choice == "Chest" then
                            -- Chest farm
                            print("chest farm enabled.")
                        elseif getgenv().settings.AutoFarm.farm_type_choice == "Multi Target" then
                            -- Multi target farm
                            print("multi target farm enabled.")
                        end
                    end
                end)
            else
                Util.notify("Auto farm disabled")
            end
        end,

        -- Get egg choice
        getEggChoice = function(choice)
            -- Parse egg name from `egg.displayName - egg.World`
            getgenv().settings.AutoHatch.egg_choice = string.match(choice[1], "^(.-) %-")
        end,

        -- auto hatch
        startAutoHatch = function()
            if getgenv().settings.AutoHatch.auto_hatch_enabled_toggle then
                Util.notify("Auto hatch enabled")
                Util.notify("Egg choice: " .. getgenv().settings.AutoHatch.egg_choice)
                task.spawn(function()
                    while getgenv().settings.AutoHatch.auto_hatch_enabled_toggle do
                        Util.notify("Hatching egg: " .. getgenv().settings.AutoHatch.egg_choice)
                        Invoke("Buy Egg", getgenv().settings.AutoHatch.egg_choice, getgenv().settings.AutoHatch.triple_hatch_toggle, getgenv().settings.AutoHatch.octuple_hatch_toggle)
                        task.wait(1.2)
                    end
                end)
            end
        end,

        -- collect free gifts
        collectGifts = function()
            if getgenv().settings.Misc.auto_collect_gifts_toggle then
                Util.notify("Auto collect gifts enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_collect_gifts_toggle do
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
            end
        end,


        -- redeem rank rewards
        redeemRankRewards = function()
            if getgenv().settings.Misc.auto_redeem_rank_rewards_toggle then
                Util.notify("Auto redeem Rank rewards enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_redeem_rank_rewards_toggle do
                        Save = Lib.Save.Get()
                        rankCooldown = Lib.Directory.Ranks[Save.Rank].rewardCooldown
                        if ((Save["RankTimer"] + rankCooldown) < os.time()) then
                            Util.notify("Redeeming rank rewards...")
                            Invoke("Redeem Rank Rewards")
                            task.wait(2)
                        else
                            print("Rank rewards not available...")
                            task.wait(60)
                        end
                    end
                end)
            end
        end,

        -- auto triple coins
        autoTripleCoins = function()
            if getgenv().settings.Misc.auto_triple_coins_toggle then
                Util.notify("Auto triple coins enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_triple_coins_toggle do
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
        end,

        -- Auto triple damage
        autoTripleDamage = function()
            if getgenv().settings.Misc.auto_triple_damage_toggle then
                Util.notify("Auto triple damage enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_triple_damage_toggle do
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
        end,

        -- Auto super lucky
        autoSuperLucky = function()
            if getgenv().settings.Misc.auto_super_lucky_toggle then
                Util.notify("Auto super lucky enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_super_lucky_toggle do
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
        end,

        -- Auto ultra lucky
        autoUltraLucky = function()
            if getgenv().settings.Misc.auto_ultra_lucky_toggle then
                Util.notify("Auto ultra lucky enabled")
                task.spawn(function()
                    while getgenv().settings.Misc.auto_ultra_lucky_toggle do
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
        end,

        -- Unlock gamepasses
        unlockGamepasses = function()
            Util.notify("Unlocking gamepasses")
            task.spawn(function()
                if getgenv().settings.Misc.unlock_gamepasses_toggle then
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
        end,

        -- Auto Collect Orbs
        autoCollectOrbs = function()
            if getgenv().settings.AutoFarm.auto_collect_orbs_toggle then
                Util.notify("Auto orbs enabled")
                task.spawn(function()
                    while getgenv().settings.AutoFarm.auto_collect_orbs_toggle do
                        local orbs = game:GetService("Workspace")["__THINGS"]:FindFirstChild("Orbs")
                        for i,v in pairs(orbs:GetChildren()) do
                            v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                        end
                        task.wait(2)
                    end
                end)
            else
                Util.notify("Auto orbs disabled")
            end
        end,

        -- Anti afk
        antiAfk = function()
            if getgenv().settings.Misc.anti_afk_toggle then
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
        end,
    }

    -- Create GUI
    local createGUI = loadstring(readfile("gpsx/gpsx_ui.lua"))()
    local gui = createGUI(group, actions)
end

function setSettingDefaults()
    getgenv().settings = {
        AutoFarm = {
            auto_farm_enabled_toggle = false,
            auto_collect_orbs_toggle = false,
            farm_area_choice = "Town",
            farm_type_choice = "Normal",
        },
        AutoHatch = {
            auto_hatch_enabled_toggle = false,
            triple_hatch_toggle = false,
            octuple_hatch_toggle = false,
            egg_choice = "Cracked Egg",
        },
        Misc = {
            unlock_gamepasses_toggle = false,
            auto_collect_gifts_toggle = false,
            auto_redeem_rank_rewards_toggle = false,
            auto_triple_coins_toggle = false,
            auto_triple_damage_toggle = false,
            auto_super_lucky_toggle = false,
            auto_ultra_lucky_toggle = false,
            anti_afk_toggle = false,
        }
    }
end

function main()
    print("Launching script...")

    -- Set default settings
    setSettingDefaults()

    -- Load util functions
    Util = loadstring(readfile("gpsx/util.lua"))()

    local playerName = game.Players.LocalPlayer.Name
    local found = false

    -- Read accounts from JSON file
    local accounts = Util.loadAccounts()

    -- Load script with settings based on account group
    for groupName, nameList in pairs(accounts) do
        if Util.isInList(nameList, playerName) then
            loadScript(groupName)
            found = true
            break
        end
    end

    -- Load script with default settings if the account isn't in a group
    if not found then
        loadScript('default')
    end
end

-- Script entry point
main()