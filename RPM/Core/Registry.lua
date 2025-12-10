-- ServerScriptService.RP.Core.Registry
local ServerScriptService = game:GetService("ServerScriptService")

local Util = require(script.Parent:WaitForChild("Util"))
local Validator = require(script.Parent:WaitForChild("Validator"))

local Registry = {}

-- Registry shape:
-- {
--   packages = {
--     [name] = {
--       Name = name,
--       Kind = "Package" | "Dev",
--       Folder = Folder,
--       Config = table,
--       Errors = { ... },
--       Warnings = { ... },
--     }
--   },
--   globalErrors = { ... },
--   countPackages = number,
--   countDevPackages = number,
-- }

local function loadPackageFromFolder(folder, kind)
    local cfgModule =
        folder:FindFirstChild("package") or
        folder:FindFirstChild("package.lua") or
        folder:FindFirstChildWhichIsA("ModuleScript")

    local entry = {
        Name = folder.Name,
        Kind = kind,
        Folder = folder,
        Config = {},
        Errors = {},
        Warnings = {},
    }

    if not cfgModule or not cfgModule:IsA("ModuleScript") then
        table.insert(entry.Errors, "No ModuleScript config found (expected 'package').")
        return entry
    end

    local ok, rawCfgOrErr = pcall(require, cfgModule)
    if not ok then
        table.insert(entry.Errors, "require failed: " .. tostring(rawCfgOrErr))
        return entry
    end

    if type(rawCfgOrErr) ~= "table" then
        table.insert(entry.Errors, "Config did not return a table.")
        return entry
    end

    local cfg, errs, warns = Validator.validatePackageConfig(folder.Name, rawCfgOrErr)
    entry.Config = cfg
    for _, msg in ipairs(errs) do
        table.insert(entry.Errors, msg)
    end
    for _, msg in ipairs(warns) do
        table.insert(entry.Warnings, msg)
    end

    return entry
end

function Registry.build(RP, CoreFolder)
    local root = RP or ServerScriptService:FindFirstChild("RP")
    local registry = {
        packages = {},
        globalErrors = {},
        countPackages = 0,
        countDevPackages = 0,
    }

    if not root then
        table.insert(registry.globalErrors, "RP folder not found in ServerScriptService.")
        return registry
    end

    local packagesFolder = root:FindFirstChild("Packages")
    local devFolder = root:FindFirstChild("Developer_Packages")

    if not packagesFolder then
        table.insert(registry.globalErrors, "RP.Packages folder missing.")
    end
    if not devFolder then
        table.insert(registry.globalErrors, "RP.Developer_Packages folder missing.")
    end

    -- Normal packages
    if packagesFolder then
        for _, child in ipairs(packagesFolder:GetChildren()) do
            if child:IsA("Folder") then
                local entry = loadPackageFromFolder(child, "Package")
                registry.packages[entry.Config.Name or child.Name] = entry
                registry.countPackages += 1
            end
        end
    end

    -- Developer packages
    if devFolder then
        for _, child in ipairs(devFolder:GetChildren()) do
            if child:IsA("Folder") then
                local entry = loadPackageFromFolder(child, "Dev")
                registry.packages[entry.Config.Name or child.Name] = entry
                registry.countDevPackages += 1
            end
        end
    end

    return registry
end

return Registry
