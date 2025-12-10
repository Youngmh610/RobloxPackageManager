-- ServerScriptService.RP.Core.Executor
local Util = require(script.Parent:WaitForChild("Util"))
local Validator = require(script.Parent:WaitForChild("Validator"))

local Executor = {}

local function getServerScriptModules(pkgEntry)
    local cfg = pkgEntry.Config
    local folder = pkgEntry.Folder
    local serverFolder = folder:FindFirstChild("server")
    if not serverFolder then
        return {}
    end

    local result = {}
    local fileList = cfg.ServerFiles or {}

    if #fileList > 0 then
        -- Explicit list from config
        for _, filename in ipairs(fileList) do
            local ms = serverFolder:FindFirstChild(filename)
            if ms and ms:IsA("ModuleScript") then
                table.insert(result, ms)
            else
                Util.log("Executor", ("[%s] Missing server file '%s'"):format(cfg.Name, filename))
            end
        end
    else
        -- Fallback: run all ModuleScripts in server folder
        for _, child in ipairs(serverFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                table.insert(result, child)
            end
        end
    end

    return result
end

local function validateFileDepsForPackage(pkgEntry)
    local cfg = pkgEntry.Config
    for _, path in ipairs(cfg.File_Dependencies or {}) do
        local ok, msg = Validator.validateFileDependency(path)
        if not ok then
            Util.log(
                "Executor",
                ("[%s] File_Dependencies error for '%s': %s")
                    :format(cfg.Name, path, msg)
            )
        end
    end
end

function Executor.runServer(registry, order)
    for _, name in ipairs(order) do
        local entry = registry.packages[name]
        local cfg = entry.Config

        if cfg.Type == "Client" then
            -- Skip pure client packages on server
            continue
        end

        if #entry.Errors > 0 then
            Util.log(
                "Executor",
                ("Skipping package '%s' due to config errors: %s")
                    :format(name, table.concat(entry.Errors, "; "))
            )
            continue
        end

        Util.log("Executor", ("Running server for package '%s'"):format(name))

        validateFileDepsForPackage(entry)

        local scripts = getServerScriptModules(entry)
        for _, ms in ipairs(scripts) do
            local result, err = Util.safeRequire(ms)
            if not result then
                warn(("[RPM][Executor][%s] Error requiring '%s': %s")
                    :format(name, ms.Name, err))
            else
                if typeof(result) == "function" then
                    local ok, runErr = pcall(result, {
                        PackageName = name,
                        Config = cfg,
                        Folder = entry.Folder,
                        Kind = entry.Kind,
                    })
                    if not ok then
                        warn(("[RPM][Executor][%s] Error running '%s': %s")
                            :format(name, ms.Name, runErr))
                    end
                end
            end
        end
    end
end

return Executor
