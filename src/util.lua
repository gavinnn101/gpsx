---@diagnostic disable: undefined-global

local Util = {}

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

function Util.loadSettings(settingsFileName)
    local settingsFilePath = "gpsx/" .. settingsFileName .. "_settings.json"

    if not isfile(settingsFilePath) then
        print("Creating " .. settingsFilePath)

        -- Create defaultSettings using the values from getgenv().settings
        local defaultSettings = getgenv().settings
        writefile(settingsFilePath, game:GetService('HttpService'):JSONEncode(defaultSettings))
    end

    local settingsJson = readfile(settingsFilePath)
    local settings = game:GetService('HttpService'):JSONDecode(settingsJson)

    return settings
end

function Util.saveSettings(settingsFileName)
    local settingsFilePath = "gpsx/" .. settingsFileName .. "_settings.json"

    if not getgenv().settings then
        print("No settings data found in getgenv().settings.")
        return
    end

    local HttpService = game:GetService("HttpService")
    local settingsJson = HttpService:JSONEncode(getgenv().settings)

    if isfile(settingsFilePath) then
        delfile(settingsFilePath)
        print("Removing old " .. settingsFilePath)
    end

    writefile(settingsFilePath, settingsJson)
    print("Settings saved to file: " .. settingsFilePath)
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

function Util.getEggData()
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
    -- area: in-game area (Winter, Forest, Axolotl Deep Ocean)

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
                    eggsData[{["name"] = ve.Name, ["world"] = v.Name}] = eggInfo
                end
            end
        end
    end
    return eggsData
end

function Util.getSortedEggList(eggsData)
    -- Generate a table containing eggs displayName
    local eggOptions = {}
    for key, eggData in pairs(eggsData or {}) do
        local displayName = eggData.displayName
        local world = key.world
        table.insert(eggOptions, {displayName = displayName, world = world})
    end

    -- Sort the eggOptions by world and then by displayName
    table.sort(eggOptions, function(a, b)
        if a.world == b.world then
            return a.displayName < b.displayName
        else
            return a.world < b.world
        end
    end)

    -- Extract the displayName and world from the sorted eggOptions and concatenate them
    local sortedDisplayNamesWithWorld = {}
    for _, option in ipairs(eggOptions) do
        table.insert(sortedDisplayNamesWithWorld, option.displayName .. " - " .. option.world)
    end
    return sortedDisplayNamesWithWorld
end

-- Get all areas
function Util.getAreas()
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

return Util