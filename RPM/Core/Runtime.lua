-- ServerScriptService.RP.Core.Runtime
local ServerScriptService = game:GetService("ServerScriptService")

local Runtime = {}

function Runtime.Start()
    local RP = ServerScriptService:FindFirstChild("RP")
    if not RP then
        warn("[RPM] RP folder not found in ServerScriptService.")
        return
    end

    local CoreFolder = RP:FindFirstChild("Core")
    if not CoreFolder then
        warn("[RPM] Core folder not found in RP.")
        return
    end

    local Util = require(CoreFolder:WaitForChild("Util"))
    local Registry = require(CoreFolder:WaitForChild("Registry"))
    local Resolver = require(CoreFolder:WaitForChild("Resolver"))
    local Executor = require(CoreFolder:WaitForChild("Executor"))

    Util.log("Runtime", "Building package registry...")
    local registry = Registry.build(RP, CoreFolder)

    Util.log(
        "Runtime",
        ("Loaded %d packages (%d dev).")
            :format(registry.countPackages, registry.countDevPackages)
    )

    if #registry.globalErrors > 0 then
        Util.log("Runtime", "Global errors detected:")
        for _, msg in ipairs(registry.globalErrors) do
            warn("[RPM][Registry] " .. msg)
        end
    end

    Util.log("Runtime", "Resolving dependencies...")
    local ok, orderOrErrors = Resolver.resolve(registry)
    if not ok then
        Util.log("Runtime", "Dependency resolution failed:")
        for _, msg in ipairs(orderOrErrors) do
            warn("[RPM][Resolver] " .. msg)
        end
        return
    end

    Util.log("Runtime", "Execution order resolved:")
    Util.log("Runtime", table.concat(orderOrErrors, " -> "))

    Util.log("Runtime", "Executing server packages...")
    Executor.runServer(registry, orderOrErrors)
    Util.log("Runtime", "Server execution complete.")
end

return Runtime
