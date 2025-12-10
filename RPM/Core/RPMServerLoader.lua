-- ServerScriptService.RPMServerLoader
local ServerScriptService = game:GetService("ServerScriptService")

local RP = ServerScriptService:WaitForChild("RP")
local Core = RP:WaitForChild("Core")
local Runtime = require(Core:WaitForChild("Runtime"))

Runtime.Start()
