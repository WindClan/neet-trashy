local i = 0
while true do
    print(tostring(i))
    i = i + 1
    coroutine.yield()
    sleep(1)
end
