function trim(s)
    s = s:gsub('\r', '')
    s = s:gsub('\n', '')
    return s:match '^%s*(.*%S)' or ''
end