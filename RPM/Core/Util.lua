-- ServerScriptService.RP.Core.Util
local Util = {}

function Util.log(tag, msg)
    print(("[RPM][%s] %s"):format(tag, msg))
end

function Util.safeRequire(moduleScript)
    local ok, result = pcall(require, moduleScript)
    if not ok then
        return nil, ("require failed: %s"):format(tostring(result))
    end
    return result
end

function Util.ensureFolder(parent, name)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

function Util.isStringArray(tbl)
    if typeof(tbl) ~= "table" then
        return false
    end
    for _, v in ipairs(tbl) do
        if typeof(v) ~= "string" then
            return false
        end
    end
    return true
end

function Util.cloneShallow(tbl)
    local new = {}
    if tbl then
        for k, v in pairs(tbl) do
            new[k] = v
        end
    end
    return new
end

return Util
