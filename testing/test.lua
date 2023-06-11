---@diagnostic disable: undefined-global

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

local Lib = require(ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"))
while not Lib.Loaded do
    RunService.Heartbeat:Wait()
end

local Client = require(ReplicatedStorage.Library.Client)
local tp = getsenv(Players.LocalPlayer.PlayerScripts.Scripts.GUIs.Teleport)
local menus = game.Players.LocalPlayer.PlayerGui.Main.Right
local Things = Workspace["__THINGS"]

-- Hooking invoke/fire functions to return true.
local old
old = hookfunction(getupvalue(Fire, 1), function(...)
 return true
end)

