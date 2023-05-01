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
    local Lib = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
    local allAreas = Util.getAreas()
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

    -- AutoCollectFreeGiftsToggle
    getgenv().Toggles.AutoCollectFreeGiftsToggle:OnChanged(function()
        print("Auto Collect Free Gifts: ", getgenv().Toggles.AutoCollectFreeGiftsToggle.Value)
        Util.CollectFreeGifts()
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