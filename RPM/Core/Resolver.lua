-- ServerScriptService.RP.Core.Resolver
local Resolver = {}

-- returns ok: boolean, result: orderList or errorMessages
function Resolver.resolve(registry)
    local pkgs = registry.packages
    local errors = {}

    -- adjacency & indegree
    local adj = {}
    local indegree = {}

    for name, _ in pairs(pkgs) do
        adj[name] = {}
        indegree[name] = 0
    end

    local function addEdge(from, to, optional)
        if not pkgs[to] then
            if optional then
                return
            else
                table.insert(
                    errors,
                    ("Missing dependency '%s' required by '%s'"):format(to, from)
                )
                return
            end
        end
        table.insert(adj[from], to)
        indegree[to] += 1
    end

    for name, entry in pairs(pkgs) do
        local cfg = entry.Config
        for _, dep in ipairs(cfg.Dependencies or {}) do
            addEdge(name, dep, false)
        end
        for _, dep in ipairs(cfg.Optional_Dependencies or {}) do
            addEdge(name, dep, true)
        end
    end

    if #errors > 0 then
        return false, errors
    end

    -- Kahn's algorithm
    local queue = {}
    for name, degree in pairs(indegree) do
        if degree == 0 then
            table.insert(queue, name)
        end
    end

    local order = {}
    while #queue > 0 do
        local node = table.remove(queue, 1)
        table.insert(order, node)

        for _, neighbor in ipairs(adj[node]) do
            indegree[neighbor] -= 1
            if indegree[neighbor] == 0 then
                table.insert(queue, neighbor)
            end
        end
    end

    local totalCount = 0
    for _ in pairs(pkgs) do
        totalCount += 1
    end

    if #order ~= totalCount then
        table.insert(errors, "Dependency cycle detected.")
        return false, errors
    end

    -- Reverse so dependencies run first
    local finalOrder = {}
    for i = #order, 1, -1 do
        table.insert(finalOrder, order[i])
    end

    return true, finalOrder
end

return Resolver
