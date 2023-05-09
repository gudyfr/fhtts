INFO = 10
DEBUG = 20
WARNING = 25
ERROR = 30

LevelsOutput = {
    [10]="I",
    [20]="D",
    [25]='W',
    [30]='E'
}

CurrentLogLevel = 25 -- Warning by default
CurrentLogTags = nil

function fhLogInit()
    Global.call('registerFhLogger', self)
end

function onFhLogSettingsUpdated(payload)
    local params = JSON.decode(payload)
    CurrentLogEnabled = params.enabled
    if params.level ~= nil then
        if params.level == "info" then
            CurrentLogLevel = 10
        elseif params.level == "debug" then
            CurrentLogLevel = 20
        elseif params.level == "warn" then
            CurrentLogLevel = 25
        elseif params.level == "error" then
            CurrentLogLevel = 30
        else
            CurrentLogLevel = 25
        end
    else
        CurrentLogLevel = 25
    end
    
    CurrentLogTags = setLogTags(params.tags)
end

function split(str, sep)
    sep = sep or "%s"
    local result={}
    for el in string.gmatch(str, "([^"..sep.."]+)") do
       table.insert(result, el)
    end
    return result
 end

function setLogTags(tags)
    if tags == nil or tags == "" then
        CurrentLogTags = nil
    else
        CurrentLogTags = {}
        for _,el in ipairs(split(tags, "%s,")) do
            CurrentLogTags[el] = 1
        end
    end
end

function fhlogObject(level, tag, object)
    fhlog(level, tag, "%s", object)
end

function fhlog(level, tag, message, ...)
    level = level or 0
    tag = tag or "Untagged"
    message = message or ""
    if level >= CurrentLogLevel then
        if CurrentLogTags == nil or CurrentLogTags[tag] ~= nil then
            local params = {}
            -- table.insert(params, Time.time)
            table.insert(params, LevelsOutput[level] or "?")
            table.insert(params, tag)
            for _,a in ipairs(table.pack(...)) do
                table.insert(params, JSON.encode(a))
            end
            local fmt = "%s %-20s " .. message
            local success, log = pcall(function() return string.format(fmt, table.unpack(params)) end)
            if success then
                print(log)
            else
                print(string.format("Error building log %s %s %s", LevelsOutput[level] or "?", tag, message))
            end
        end
    end
end

function printStackTrace()
    print(debug.traceback())
end
