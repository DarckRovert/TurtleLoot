-- TurtleLoot Shims
-- Compatibility layer for different WoW versions

local TL = TurtleLoot;

-- String compatibility for LUA 5.0 (Vanilla WoW)
if not string.gmatch then
    string.gmatch = string.gfind;
end

if not string.match then
    -- string.match doesn't exist in LUA 5.0, use string.find instead
    -- This shim supports multiple captures
    string.match = function(str, pattern)
        local results = {string.find(str, pattern)};
        if table.getn(results) > 2 then
            -- Remove first two elements (start and end positions)
            table.remove(results, 1);
            table.remove(results, 1);
            return unpack(results);
        end
        return nil;
    end
end

-- Table compatibility
if not table.getn then
    table.getn = function(t)
        local count = 0;
        for _ in pairs(t) do
            count = count + 1;
        end
        return count;
    end
end

-- Math compatibility
if not math.mod then
    math.mod = mod;
end

-- GetAddOnMetadata compatibility
if not GetAddOnMetadata and C_AddOns then
    GetAddOnMetadata = C_AddOns.GetAddOnMetadata;
end

-- String trim function (doesn't exist in Vanilla)
if not string.trim then
    string.trim = function(s)
        return (string.gsub(s, "^%s*(.-)%s*$", "%1"));
    end
end
