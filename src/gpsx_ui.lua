---@diagnostic disable: undefined-global

function createGUI(group, areas)
    -- Load util functions
    Util = loadstring(readfile("gpsx/util.lua"))()

    print("Creating GUI...")
    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

    local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
    local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

    -- Hand the library over to our managers
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    -- Set save folder to `workspace/gpsx`
    ThemeManager:SetFolder('gpsx')
    SaveManager:SetFolder('gpsx')

    local Window = Library:CreateWindow({
        Title = 'GPSX | GaviNNN#3281',
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })

    local Tabs = {
        -- Creates a new tab titled Main
        ["Auto Farm"] = Window:AddTab("Auto Farm"),
        ["Auto Hatch"] = Window:AddTab("Auto Hatch"),
        ["Misc"] = Window:AddTab("Misc"),
        ["UI Settings"] = Window:AddTab("UI Settings"),
    }


    -- Auto Farm Tab
    -- Auto farm group box
    local AutoFarmGroupBox = Tabs["Auto Farm"]:AddLeftGroupbox('Auto Farm')

    -- Auto farm enabled toggle
    AutoFarmGroupBox:AddToggle("AutoFarmEnabledToggle", {
        Text = "Auto Farm Enabled",
        Default = false,
        Tooltip = "Turn on to start auto farm. Make sure to select farm type and area!",

    })

    -- Auto collect orbs toggle
    AutoFarmGroupBox:AddToggle("AutoCollectOrbsToggle", {
        Text = "Auto Collect Orbs",
        Default = false,
        Tooltip = "Turn on to auto collect orbs(loot.)",
    })

    -- Auto collect lootbags toggle
    AutoFarmGroupBox:AddToggle("AutoCollectLootbagsToggle", {
        Text = "Auto Collect Loot Bags",
        Default = false,
        Tooltip = "Turn on to auto collect loot bags.",
    })

    -- Auto farm type dropdown
    AutoFarmGroupBox:AddDropdown('FarmTypeDropdown', {
        Values = {"Normal", "Nearest", "Multi Target", "Highest Value"},
        Default = "Normal", -- number index of the value / string
        Multi = false, -- true / false, allows multiple choices to be selected
        Text = 'Auto Farm Type',
        Tooltip = 'Type of auto farm to use.',
    })

    -- Auto farm area dropdown
    AutoFarmGroupBox:AddDropdown("FarmAreaDropdown", {
        Values = areas,
        Default = "Town", -- number index of the value / string
        Multi = false, -- true / false, allows multiple choices to be selected
        Text = "Auto Farm Area",
        Tooltip = "Area to auto farm in.",
    })

    -- Auto comet farm groupbox
    local AutoCometFarmGroupBox = Tabs["Auto Farm"]:AddRightGroupbox("Auto Comet Farm")

    -- Auto comet farm enabled toggle
    AutoCometFarmGroupBox:AddToggle("AutoCometFarmEnabledToggle", {
        Text = "Auto Comet Farm Enabled",
        Default = false,
        Tooltip = "Turn on to start auto comet farm.",
    })

    -- Auto hatch group box
    local AutoHatchGroupBox = Tabs["Auto Hatch"]:AddLeftGroupbox("Auto Hatch")
    -- Auto hatch enabled toggle
    AutoHatchGroupBox:AddToggle("AutoHatchEnabledToggle", {
        Text = "Auto Hatch Enabled",
        Default = false,
        Tooltip = "Turn on to start auto hatch.",
    })

    -- SkipEggAnimationToggle
    AutoHatchGroupBox:AddToggle("SkipEggAnimationToggle", {
        Text = "Skip Egg Animation",
        Default = false,
        Tooltip = "Turn on to skip egg hatch animation.",
    })

    -- Enable triple hatch toggle
    AutoHatchGroupBox:AddToggle("EnableTripleHatchToggle", {
        Text = "Enable Triple Hatch",
        Default = false,
        Tooltip = "Enable triple hatch gamepass (Must own.)",
    })

    -- Enable octuple hatch toggle
    AutoHatchGroupBox:AddToggle("EnableOctupleHatchToggle", {
        Text = "Enable Octuple Hatch",
        Default = false,
        Tooltip = "Enable octuple hatch gamepass (Must own.)",
    })

    -- Auto hatch egg choice dropdown
    local eggData = Util.GetEggData()
    local eggNameList = Util.GetEggNamesList(eggData)
    AutoHatchGroupBox:AddDropdown("AutoHatchEggChoiceDropdown", {
        Values = eggNameList,
        Default = "Cafe Egg", -- number index of the value / string
        Multi = false, -- true / false, allows multiple choices to be selected
        Text = "Auto Hatch Egg Choice",
        Tooltip = "Egg to auto hatch.",
    })


    -- Misc Tab
    -- Misc group box
    local MiscGroupBox = Tabs["Misc"]:AddLeftGroupbox("Misc")

    -- Unlock gamepasses toggle
    MiscGroupBox:AddToggle("UnlockGamepassesToggle", {
        Text = "Unlock Gamepasses",
        Default = false,
        Tooltip = "Turn on to unlock all gamepasses.",
    })

    -- Auto Collect Free Gifts Toggle
    MiscGroupBox:AddToggle("AutoCollectFreeGiftsToggle", {
        Text = "Auto Collect Free Gifts",
        Default = false,
        Tooltip = "Turn on to auto collect free gifts.",
    })

    -- Auto collect rank rewards toggle
    MiscGroupBox:AddToggle("AutoCollectRankRewardsToggle", {
        Text = "Auto Collect Rank Rewards",
        Default = false,
        Tooltip = "Turn on to auto collect rank rewards (must be in range.)",
    })

    -- Anti AFK toggle
    MiscGroupBox:AddToggle("AntiAfkToggle", {
        Text = "Anti AFK",
        Default = false,
        Tooltip = "Turn on to enable anti afk.",
    })

    -- Friend all players button
    MiscGroupBox:AddButton("Friend all players", function() Util.FriendAllPlayers() end)

    -- Misc group box right
    local AutoBoostGroupBox = Tabs["Misc"]:AddRightGroupbox("Auto Boosts")

    -- Auto Triple Coins toggle
    AutoBoostGroupBox:AddToggle("AutoTripleCoinsToggle", {
        Text = "Auto Triple Coins",
        Default = false,
        Tooltip = "Turn on to auto triple coins.",
    })

    -- Auto Triple Damage toggle
    AutoBoostGroupBox:AddToggle("AutoTripleDamageToggle", {
        Text = "Auto Triple Damage",
        Default = false,
        Tooltip = "Turn on to auto triple damage.",
    })

    -- Auto Super Lucky toggle
    AutoBoostGroupBox:AddToggle("AutoSuperLuckyToggle", {
        Text = "Auto Super Lucky",
        Default = false,
        Tooltip = "Turn on to auto super lucky.",
    })

    -- Auto Ultra Lucky toggle
    AutoBoostGroupBox:AddToggle("AutoUltraLuckyToggle", {
        Text = "Auto Ultra Lucky",
        Default = false,
        Tooltip = "Turn on to auto ultra lucky.",
    })

    -- Auto server boost group box
    local AutoServerBoostGroupBox = Tabs["Misc"]:AddRightGroupbox("Auto Server Boosts")

    -- Auto server triple coins toggle
    AutoServerBoostGroupBox:AddToggle("AutoServerTripleCoinsToggle", {
        Text = "Auto Server Triple Coins",
        Default = false,
        Tooltip = "Auto enable server triple coins.",
    })

    -- Auto server triple damage toggle
    AutoServerBoostGroupBox:AddToggle("AutoServerTripleDamageToggle", {
        Text = "Auto Server Triple Damage",
        Default = false,
        Tooltip = "Auto enable server triple damage.",
    })

    -- Auto server super lucky toggle
    AutoServerBoostGroupBox:AddToggle("AutoServerSuperLuckyToggle", {
        Text = "Auto Server Super Lucky",
        Default = false,
        Tooltip = "Auto enable server super lucky.",
    })

    -- Resource Savers box left
    local ResourceSaversGroupBoxLeft = Tabs["Misc"]:AddLeftGroupbox("Resource Savers")

    -- Low FPS toggle
    ResourceSaversGroupBoxLeft:AddToggle("LowFPSToggle", {
        Text = "Enable Low FPS",
        Default = false,
        Tooltip = "Turn on to lower FPS to reduce lag.",
    })

    -- Disable Graphics Rendering toggle
    ResourceSaversGroupBoxLeft:AddToggle("DisableGraphicsRenderingToggle", {
        Text = "Disable Graphics Rendering",
        Default = false,
        Tooltip = "Turn on to disable graphics rendering.",
    })

    -- Function to run onUnload
    Library:OnUnload(function()
        print("GPSX Unloaded!")
        Library.Unloaded = true
    end)


    -- UI Settings Tab
    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
    -- I set NoUI so it does not show up in the keybinds menu
    MenuGroup:AddButton("Unload", function() Library:Unload() end)
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

    -- Add config section to GUI
    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    -- Add theme section to GUI
    ThemeManager:ApplyToTab(Tabs['UI Settings'])

    -- Load config based on account group
    -- local group = "autofarm" -- for testing
    SaveManager:Load(group)
    Library:Notify("Loaded config: " .. group)
end
return createGUI