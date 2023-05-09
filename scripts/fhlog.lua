INFO = 10
DEBUG = 20
ERROR = 30

LevelsOutput = {
    [10]="I",
    [20]="D",
    [30]='E'
}

CurrentLogEnabled = false
CurrentLogLevel = 20 -- Debug by default
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
        elseif params.level == "error" then
            CurrentLogLevel = 30
        end
    else
        CurrentLogLevel = 20
    end
    
    CurrentLogTags = params.tags
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
    if CurrentLogEnabled and level >= CurrentLogLevel then
        if CurrentLogTags == nil or CurrentLogTags[tag] ~= nil then
            local params = {}
            table.insert(params, LevelsOutput[level])
            table.insert(params, tag)
            for _,a in ipairs(arg) do
                table.insert(params, JSON.encode(a))
            end
            local fmt = "%s %-20.19s" .. message
            local log = string.format(fmt, params)
            print(log)
        end
    end
end
