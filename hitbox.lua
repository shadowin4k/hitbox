local httpRequest = syn and syn.request or http_request or request or (http and http.request)
local scriptURL = "https://raw.githubusercontent.com/shadowin4k/hitbox/refs/heads/main/hitbox.lua"

local cachedCode = nil
local lastFetchTime = 0
local fetchCooldown = 60 -- seconds between fetches to reduce requests

local function safeWait(minMs, maxMs)
    task.wait(math.random(minMs, maxMs) / 1000)
end

local function safeGet(url)
    -- Only fetch if cooldown elapsed or no cached code
    if cachedCode and (tick() - lastFetchTime) < fetchCooldown then
        return cachedCode
    end

    safeWait(10, 50) -- delay before request

    local body
    if httpRequest then
        local ok, res = pcall(function()
            return httpRequest({Url = url, Method = "GET"}).Body
        end)
        if ok and res then
            body = res
        end
    else
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and res then
            body = res
        end
    end

    safeWait(10, 50) -- delay after request

    if body then
        cachedCode = body
        lastFetchTime = tick()
    end

    return body
end

local code = safeGet(scriptURL)

if code then
    local func, err = loadstring(code)
    if typeof(func) == "function" then
        coroutine.wrap(function()
            local ok, e = pcall(func)
            -- silent fail, no output
        end)()
    end
end
