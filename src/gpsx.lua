---@diagnostic disable: undefined-global

function loadScript(arg)
    -- Wait for game to load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    Util.bypassAC()

    -- Main script functionality
    local group = arg

    -- Variables
    local allAreas = Util.GetAreas()
    local areas = Util.GetAreaNames(allAreas)

    -- Create GUI
    local createGUI = loadstring(readfile("gpsx/gpsx_ui.lua"))()
    local gui = createGUI(group, areas)

    Util.notify("Script loaded with settings: " .. group)

    -- AutoFarmEnabledToggle
    getgenv().Toggles.AutoFarmEnabledToggle:OnChanged(function()
        print("Auto Farm Enabled: ", getgenv().Toggles.AutoFarmEnabledToggle.Value)
        Util.AutoFarm()
    end)

    -- AutCollectOrbsToggle
    getgenv().Toggles.AutoCollectOrbsToggle:OnChanged(function()
        print("Auto Collect Orbs: ", getgenv().Toggles.AutoCollectOrbsToggle.Value)
        Util.AutoCollectOrbs()
    end)

    -- AutoCollectLootbagsToggle
    getgenv().Toggles.AutoCollectLootbagsToggle:OnChanged(function()
        print("Auto Collect Lootbags: ", getgenv().Toggles.AutoCollectLootbagsToggle.Value)
        Util.AutoCollectLootbags()
    end)

    -- FarmTypeDropdown
    getgenv().Options.FarmTypeDropdown:OnChanged(function()
        -- This is a boolean consumed by AutoFarm.
        print('Using auto farm type: ', getgenv().Options.FarmTypeDropdown.Value)
    end)

    -- FarmAreaDropdown
    getgenv().Options.FarmAreaDropdown:OnChanged(function()
        -- This is a boolean consumed by AutoFarm.
        print('Using auto farm area: ', getgenv().Options.FarmAreaDropdown.Value)
    end)

    -- AutoCometFarmEnabledToggle
    getgenv().Toggles.AutoCometFarmEnabledToggle:OnChanged(function()
        print("Auto Comet Farm Enabled: ", getgenv().Toggles.AutoCometFarmEnabledToggle.Value)
        Util.AutoCometFarm()
    end)

    -- AutoHatchEnabledToggle
    getgenv().Toggles.AutoHatchEnabledToggle:OnChanged(function()
        print("Auto Hatch Enabled: ", getgenv().Toggles.AutoHatchEnabledToggle.Value)
        Util.AutoHatch()
    end)

    -- EnableTripleHatchToggle
    getgenv().Toggles.EnableTripleHatchToggle:OnChanged(function()
        -- This is a boolean consumed by AutoHatch.
        print("Enable Triple Hatch: ", getgenv().Toggles.EnableTripleHatchToggle.Value)
    end)

    -- EnableOctupleHatchToggle
    getgenv().Toggles.EnableOctupleHatchToggle:OnChanged(function()
        -- This is a boolean consumed by AutoHatch.
        print("Enable Octuple Hatch: ", getgenv().Toggles.EnableOctupleHatchToggle.Value)
    end)

    -- AutoHatchEggChoiceDropdown
    getgenv().Options.AutoHatchEggChoiceDropdown:OnChanged(function()
        -- This is a boolean consumed by AutoHatch.
        print("Using auto hatch egg choice: ", getgenv().Options.AutoHatchEggChoiceDropdown.Value)
    end)

    -- UnlockGamepassesToggle
    getgenv().Toggles.UnlockGamepassesToggle:OnChanged(function()
        print("Unlock Gamepasses: ", getgenv().Toggles.UnlockGamepassesToggle.Value)
        Util.UnlockGamepasses()
    end)

    -- AutoCollectFreeGiftsToggle
    getgenv().Toggles.AutoCollectFreeGiftsToggle:OnChanged(function()
        print("Auto Collect Free Gifts: ", getgenv().Toggles.AutoCollectFreeGiftsToggle.Value)
        Util.CollectFreeGifts()
    end)

    -- AutoCollectRankRewards
    getgenv().Toggles.AutoCollectRankRewardsToggle:OnChanged(function()
        print("Auto Collect Rank Rewards: ", getgenv().Toggles.AutoCollectRankRewardsToggle.Value)
        Util.CollectRankRewards()
    end)

    -- Anti AFK toggle
    getgenv().Toggles.AntiAfkToggle:OnChanged(function()
        print("Anti AFK: ", getgenv().Toggles.AntiAfkToggle.Value)
        Util.AntiAfk()
    end)

    -- AutoTripleCoinsToggle
    getgenv().Toggles.AutoTripleCoinsToggle:OnChanged(function()
        print("Auto Triple Coins: ", getgenv().Toggles.AutoTripleCoinsToggle.Value)
        Util.AutoTripleCoins()
    end)

    -- AutoTripleDamageToggle
    getgenv().Toggles.AutoTripleDamageToggle:OnChanged(function()
        print("Auto Triple Damage: ", getgenv().Toggles.AutoTripleDamageToggle.Value)
        Util.AutoTripleDamage()
    end)

    -- AutoSuperLuckyToggle
    getgenv().Toggles.AutoSuperLuckyToggle:OnChanged(function()
        print("Auto Super Lucky: ", getgenv().Toggles.AutoSuperLuckyToggle.Value)
        Util.AutoSuperLucky()
    end)

    -- AutoUltraLuckyToggle
    getgenv().Toggles.AutoUltraLuckyToggle:OnChanged(function()
        print("Auto Ultra Lucky: ", getgenv().Toggles.AutoUltraLuckyToggle.Value)
        Util.AutoUltraLucky()
    end)

    -- AutoServerTripleCoinsToggle
    getgenv().Toggles.AutoServerTripleCoinsToggle:OnChanged(function()
        print("Auto Server Triple Coins: ", getgenv().Toggles.AutoServerTripleCoinsToggle.Value)
        Util.AutoServerTripleCoins()
    end)

    -- AutoServerTripleDamageToggle
    getgenv().Toggles.AutoServerTripleDamageToggle:OnChanged(function()
        print("Auto Server Triple Damage: ", getgenv().Toggles.AutoServerTripleDamageToggle.Value)
        Util.AutoServerTripleDamage()
    end)

    -- AutoServerSuperLuckyToggle
    getgenv().Toggles.AutoServerSuperLuckyToggle:OnChanged(function()
        print("Auto Server Super Lucky: ", getgenv().Toggles.AutoServerSuperLuckyToggle.Value)
        Util.AutoServerSuperLucky()
    end)

    -- SkipEggAnimationToggle
    getgenv().Toggles.SkipEggAnimationToggle:OnChanged(function()
        print("Skip Egg Animation: ", getgenv().Toggles.SkipEggAnimationToggle.Value)
        Util.SkipEggAnimation()
    end)

    -- LowFPSToggle
    getgenv().Toggles.LowFPSToggle:OnChanged(function()
        print("Low FPS: ", getgenv().Toggles.LowFPSToggle.Value)
        Util.SetFps(10)
    end)

    -- DisableGraphicsRenderingToggle
    getgenv().Toggles.DisableGraphicsRenderingToggle:OnChanged(function()
        print("Disable Graphics Rendering: ", getgenv().Toggles.DisableGraphicsRenderingToggle.Value)
        Util.SetGraphicsRendering()
    end)

end

function main()
    print("Launching script...")

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