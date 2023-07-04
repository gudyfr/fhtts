function Async (f, ...)
    local co = coroutine.create(f)
    local function exec(...)
      local ok, data = coroutine.resume(co, ...)
      if not ok then
        error(debug.traceback(co, data))
      end
      if coroutine.status(co) ~= "dead" then
        data(exec)
      end
    end
    exec(...)
 end