-- ServerScriptService.RP.Core.Validator
local Util = require(script.Parent:WaitForChild("Util"))

local Validator = {}

local function hasSpaces(str)
    return str:match("%s") ~= nil
end

local function normalizeType(t)
    if typeof(t) ~= "string" then
        return "Both"
    end
    local lower = t:lower()
    if lower == "server" then return "Server" end
    if lower == "client" then return "Client" end
    return "Both"
end

function Validator.validatePackageConfig(pkgName, rawCfg)
    local cfg = Util.cloneShallow(rawCfg or {})
    local errors = {}
    local warnings = {}

    -- Name
    cfg.Name = cfg.Name or pkgName
    if hasSpaces(cfg.Name) then
        table.insert(errors, "Name cannot contain spaces.")
    end

    -- Version / meta
    cfg.Version = cfg.Version or "1.0.0"
    cfg.Author = cfg.Author or ""
    cfg.Description = cfg.Description or ""

    -- Type
    cfg.Type = normalizeType(cfg.Type)

    -- Arrays
    local function ensureArray(fieldName)
        local arr = cfg[fieldName]
        if arr == nil then
            cfg[fieldName] = {}
            return
        end
        if not Util.isStringArray(arr) then
            table.insert(errors, fieldName .. " must be an array of strings.")
            cfg[fieldName] = {}
        end
    end

    ensureArray("Dependencies")
    ensureArray("Optional_Dependencies")
    ensureArray("File_Dependencies")
    ensureArray("ServerFiles")
    ensureArray("ClientFiles")

    return cfg, errors, warnings
end

-- Validate "game.Workspace.Part" style paths
function Validator.validateFileDependency(path)
    if typeof(path) ~= "string" or path == "" then
        return false, "Empty or non-string File_Dependency."
    end

    local segments = string.split(path, ".")
    if segments[1] ~= "game" then
        return false, "File_Dependency must start with 'game'."
    end

    local current = game
    for i = 2, #segments do
        local child = current:FindFirstChild(segments[i])
        if not child then
            return false, ("Missing instance at segment '%s'."):format(segments[i])
        end
        current = child
    end

    return true
end

return Validator
