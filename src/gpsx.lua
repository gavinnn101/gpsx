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
    Util.loadSettings(group)
    local HttpService = game:GetService('HttpService')

    -- Bypass environment check to allow use of invoke and fire
    -- https://v3rmillion.net/showthread.php?tid=1198487
    local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
    local Fire, Invoke = Network.Fire, Network.Invoke
    -- Hooking the _check function in the module to bypass the anticheat.
    local old
    old = hookfunction(getupvalue(Fire, 1), function(...)
       return true
    end)

    local player = game.Players.LocalPlayer

    Util.notify("Script loaded with settings: " .. group)

    -- Game automation functions linked to Rayfield GUI components in gpsx_ui.lua
    local actions = {
        -- auto farm
        startAutoFarm = function(status)
            if status then
                Util.notify("Auto farm enabled")
            else
                Util.notify("Auto farm disabled")
            end
        end,

        -- Get egg choice
        getEggChoice = function(choice)
            -- Parse egg name from `egg.displayName - egg.World`
            eggChoice = string.match(choice[1], "^(.-) %-")
        end,

        -- auto hatch
        startAutoHatch = function()
            if getgenv().settings.AutoHatch.auto_hatch_enabled_toggle then
                Util.notify("Auto hatch enabled")
                Util.notify("Egg choice: " .. getgenv().settings.AutoHatch.egg_choice)
                task.spawn(function()
                    while getgenv().settings.AutoHatch.auto_hatch_enabled_toggle do
                        Util.notify("Hatching egg: " .. getgenv().settings.AutoHatch.egg_choice)
                        Invoke("Buy Egg", getgenv().settings.AutoHatch.egg_choice)
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
    }

    -- Create GUI
    local createGUI = loadstring(readfile("gpsx/gpsx_ui.lua"))()
    local gui = createGUI(group, actions)
end

function setSettingDefaults()
    getgenv().settings = {
        AutoFarm = {
            auto_farm_enabled_toggle = false
        },
        AutoHatch = {
            auto_hatch_enabled_toggle = false,
            egg_choice = {"Cracked Egg"}
        },
        Misc = {
            auto_collect_gifts_toggle = false,
            auto_redeem_rank_rewards_toggle = false
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