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
            Name = "GPSX | GaviNNN#3281",
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
                actions.startAutoFarm()
            end,
         })

        -- Auto collect orbs toggle
        local autoCollectOrbsToggle = autoFarmTab:CreateToggle({
            Name = "Auto Collect Orbs",
            CurrentValue = getgenv().settings.AutoFarm.auto_collect_orbs_toggle,
            Flag = "auto_collect_orbs_toggle",
            Callback = function(Value)
                getgenv().settings.AutoFarm.auto_collect_orbs_toggle = Value
                actions.autoCollectOrbs()
            end,
        })

        -- Farm type dropdown
        local farmTypeDropdown = autoFarmTab:CreateDropdown({
            Name = "Auto Farm Type",
            Options = {"Normal", "Chest", "Multi Target"},
            CurrentOption = getgenv().settings.AutoFarm.farm_type_choice,
            MultipleOptions = false,
            Flag = "farm_area_choice_dropdown_toggle",
            Callback = function(Option)
                getgenv().settings.AutoFarm.farm_type_choice = Option
                actions.getFarmChoice(Option)
            end,
         })

        -- Auto farm area dropdown
        local areaList = Util.getAreas()
        local farmAreaChoiceDropdown = autoFarmTab:CreateDropdown({
            Name = "Auto Farm Area",
            Options = areaList,
            CurrentOption = getgenv().settings.AutoFarm.farm_area_choice,
            MultipleOptions = false,
            Flag = "farm_area_choice_dropdown_toggle",
            Callback = function(Option)
                getgenv().settings.AutoFarm.farm_area_choice = Option
                actions.getFarmChoice(Option)
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

         local gamepassDisclaimerSection = autoHatchTab:CreateSection("Must own gamepass to use:")

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

        -- Unlock gamepass section
        local unlockGamepassesSection = miscTab:CreateSection("Unlock gamepasses:")

        -- Unlock gamepasses toggle
        local unlockGamepassesToggle = miscTab:CreateToggle({
            Name = "Unlock gamepasses (only teleport is real)",
            CurrentValue = getgenv().settings.Misc.unlock_gamepasses_toggle,
            Flag = "unlock_gamepasses_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.unlock_gamepasses_toggle = Value
                if Value then
                    actions.unlockGamepasses()
                else
                    Util.notify("Unlock gamepasses disabled")
                end
            end,
        })

        -- Auto claim section
        local autoClaimSection = miscTab:CreateSection("Auto claim:")

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

        local autoBoostSection = miscTab:CreateSection("Auto boost:")

        -- Auto triple coins toggle
        local autoTripleCoinsToggle = miscTab:CreateToggle({
            Name = "Auto triple coins",
            CurrentValue = getgenv().settings.Misc.auto_triple_coins_toggle,
            Flag = "auto_triple_coins_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.auto_triple_coins_toggle = Value
                if Value then
                    actions.autoTripleCoins()
                else
                    Util.notify("Auto triple coins disabled")
                end
            end,
        })

        -- Auto triple damage toggle
        local autoTripleDamageToggle = miscTab:CreateToggle({
            Name = "Auto triple damage",
            CurrentValue = getgenv().settings.Misc.auto_triple_damage_toggle,
            Flag = "auto_triple_damage_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.auto_triple_damage_toggle = Value
                if Value then
                    actions.autoTripleDamage()
                else
                    Util.notify("Auto triple damage disabled")
                end
            end,
        })

        -- Auto super lucky toggle
        local autoSuperLuckyToggle = miscTab:CreateToggle({
            Name = "Auto super lucky",
            CurrentValue = getgenv().settings.Misc.auto_super_lucky_toggle,
            Flag = "auto_super_lucky_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.auto_super_lucky_toggle = Value
                if Value then
                    actions.autoSuperLucky()
                else
                    Util.notify("Auto super lucky disabled")
                end
            end,
        })

        -- Auto ultra lucky toggle
        local autoUltraLuckyToggle = miscTab:CreateToggle({
            Name = "Auto ultra lucky",
            CurrentValue = getgenv().settings.Misc.auto_ultra_lucky_toggle,
            Flag = "auto_ultra_lucky_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.auto_ultra_lucky_toggle = Value
                if Value then
                    actions.autoUltraLucky()
                else
                    Util.notify("Auto ultra lucky disabled")
                end
            end,
        })

        -- Other settings section
        local otherSettingsSection = miscTab:CreateSection("Other settings:")

        -- Anti afk toggle
        local antiAfkToggle = miscTab:CreateToggle({
            Name = "Anti AFK",
            CurrentValue = getgenv().settings.Misc.anti_afk_toggle,
            Flag = "anti_afk_toggle",
            Callback = function(Value)
                getgenv().settings.Misc.anti_afk_toggle = Value
                actions.antiAfk()
            end,
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