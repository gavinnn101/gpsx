---@diagnostic disable: undefined-global

function createGUI(group, actions)
    print("Creating GUI...")
    getgenv().SecureMode = true
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window

    -- Load util functions
    Util = loadstring(readfile("gpsx/util.lua"))()

    local function createMainWindow()
        print("Creating main window...")
        Window = Rayfield:CreateWindow({
            Name = "GPSX",
            LoadingTitle = "GPSX Loading",
            LoadingSubtitle = "GaviNNN#3281",
            ConfigurationSaving = {
               Enabled = false,
               FolderName = "gpsx",
               FileName = group .. "_settings",
            },
            Discord = {
               Enabled = false,
               Invite = "randomninvalidcode123", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
               RememberJoins = true -- Set this to false to make them join the discord every time they load it up
            },
            KeySystem = false, -- Set this to true to use our key system
            KeySettings = {
               Title = "Untitled",
               Subtitle = "Key System",
               Note = "No method of obtaining the key is provided",
               FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
               SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
               GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
               Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
            }
         })
         return Window
    end

    -- Auto Farm tab
    local function createAutoFarmTab()
        print("Creating Auto Farm tab...")
        local autoFarmTab = Window:CreateTab("Auto Farm")

        -- Auto Farm Enabled toggle
        local autoFarmEnabledToggle = autoFarmTab:CreateToggle({
            Name = "Auto Farm Enabled",
            CurrentValue = getgenv().settings.AutoFarm.auto_farm_enabled_toggle,
            Flag = "auto_farm_enabled_toggle",
            Callback = function(Value)
                getgenv().settings.AutoFarm.auto_farm_enabled_toggle = Value
                actions.startAutoFarm(Value)
            end,
         })
    end

    -- Auto Hatch tab
    local function createAutoHatchTab()
        print("Creating Auto Hatch tab...")
        local autoHatchTab = Window:CreateTab("Auto Hatch")

        -- Auto Hatch Enabled toggle
        local autoHatchEnabledToggle = autoHatchTab:CreateToggle({
            Name = "Auto Hatch Enabled",
            CurrentValue = getgenv().settings.AutoHatch.auto_hatch_enabled_toggle,
            Flag = "auto_hatch_enabled_toggle",
            Callback = function(Value)
                getgenv().settings.AutoHatch.auto_hatch_enabled_toggle = Value
                if Value then
                    actions.startAutoHatch()
                else
                    Util.notify("Auto hatch disabled")
                end
                
            end,
        })

         -- Auto Hatch Egg dropdowns section
         local eggChoicesSection = autoHatchTab:CreateSection("Egg Choice Section")

         -- Auto Hatch Egg dropdown
         local eggData = Util.getEggData()
         local sortedEggsList = Util.getSortedEggList(eggData)
         local eggChoiceDropdown = autoHatchTab:CreateDropdown({
            Name = "Egg Choice",
            Options = sortedEggsList,
            CurrentOption = getgenv().settings.AutoHatch.egg_choice,
            MultipleOptions = false,
            Flag = "egg_choice_dropdown_toggle",
            Callback = function(Option)
                getgenv().settings.AutoHatch.egg_choice = Option
                actions.getEggChoice(Option)
            end,
         })

         -- Triple hatch toggle
        local tripleHatchToggle = autoHatchTab:CreateToggle({
            Name = "Triple Hatch",
            CurrentValue = getgenv().settings.AutoHatch.triple_hatch_toggle,
            Flag = "triple_hatch_toggle",
            Callback = function(Value)
                getgenv().settings.AutoHatch.triple_hatch_toggle = Value
                if Value then
                    Util.notify("Triple hatch enabled")
                else
                    Util.notify("Triple hatch disabled")
                end
            end,
        })

        -- Octuple hatch toggle
        local octupleHatchToggle = autoHatchTab:CreateToggle({
            Name = "Octuple Hatch",
            CurrentValue = getgenv().settings.AutoHatch.octuple_hatch_toggle,
            Flag = "octuple_hatch_toggle",
            Callback = function(Value)
                getgenv().settings.AutoHatch.octuple_hatch_toggle = Value
                if Value then
                    Util.notify("Octuple hatch enabled")
                else
                    Util.notify("Octuple hatch disabled")
                end
            end,
        })
    end

    -- Misc settings tab
    local function createMiscTab()
        print("Creating Misc tab...")
        local miscTab = Window:CreateTab("Misc")

        -- Collect free gifts toggle
        local collectGiftsToggle = miscTab:CreateToggle({
            Name = "Collect free gifts",
            CurrentValue = getgenv().settings.Misc.auto_collect_gifts_toggle,
            Flag = "collect_gifts_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.auto_collect_gifts_toggle = Value
                if Value then
                    actions.collectGifts()
                else
                    Util.notify("Auto collect gifts disabled")
                end
            end,
        })

        -- Redeem rank rewards toggle
        local redeemRankRewardsToggle = miscTab:CreateToggle({
            Name = "Redeem rank rewards",
            CurrentValue = getgenv().settings.Misc.auto_redeem_rank_rewards_toggle,
            Flag = "redeem_rank_rewards_toggle",
            Callback = function(Value)
                print("Redeem rank rewards toggle callback. Value: " .. tostring(Value))
                getgenv().settings.Misc.auto_redeem_rank_rewards_toggle = Value
                if Value then
                    actions.redeemRankRewards()
                else
                    Util.notify("Auto redeem Rank rewards disabled")
                end
            end
        })
    end

    -- Create settings tab function
    local function createSettingsTab()
        print("Creating Settings tab...")
        local settingsTab = Window:CreateTab("Settings")
        -- Destroy GUI button
        local destroyGUIButton = settingsTab:CreateButton({
            Name = "Destroy GUI",
            Callback = function()
                Rayfield:Destroy()
            end
        })

        -- Save Settings button
        local saveSettingsButton = settingsTab:CreateButton({
            Name = "Save Settings",
            Callback = function()
                Util.saveSettings(group)
                Util.notify("Settings saved")
            end
        })
    end

    -- Create GUI components
    createMainWindow()
    createAutoFarmTab()
    createAutoHatchTab()
    createMiscTab()
    createSettingsTab()
end
return createGUI