local UI = UI

local Config = {
    DesyncEnabled = false,
    TimerEnabled = false,
    TimerInterval = 10,
}

local DESYNC_FFLAG_OFFSET = 0x7F22158 -- needs updating every rblx update u stoopy

local base_address = getbase()

local loop_running = false
local write_running = false

local memory_write_fn = memory_write
local task_wait = task.wait
local task_spawn = task.spawn

local function applyDesyncState(state_value)
    local target_address = base_address + DESYNC_FFLAG_OFFSET
    pcall(memory_write_fn, "byte", target_address, state_value)
end

local function startWriteLoop()
    write_running = false
    task_wait()

    if not Config.DesyncEnabled then return end

    write_running = true

    task_spawn(function()
        while write_running do
            local addr = base_address + DESYNC_FFLAG_OFFSET
            pcall(memory_write_fn, "byte", addr, 1)
            task_wait()
        end
    end)
end

local function startTimerLoop()
    loop_running = false
    task_wait()

    if not Config.TimerEnabled then return end

    loop_running = true

    task_spawn(function()
        while loop_running do
            if Config.DesyncEnabled then
                applyDesyncState(0)
                task_wait(0.01)
                applyDesyncState(1)
            end
            task_wait(Config.TimerInterval)
        end
    end)
end

UI.AddTab("Desync Control", function(tab)
    local main_sec = tab:Section("Desync by bubzie", "Left")

    main_sec:Toggle("DesyncToggle", "Enable Desync", Config.DesyncEnabled, function(value)
        Config.DesyncEnabled = value

        if Config.DesyncEnabled then
            applyDesyncState(1)
            startWriteLoop()

            if Config.TimerEnabled then
                startTimerLoop()
            end
        else
            applyDesyncState(0)
            loop_running = false
            write_running = false
        end
    end)
    main_sec:Tip("Toggles the desync on/off.")

    main_sec:Toggle("TimerToggle", "Enable Auto-Toggle Timer", Config.TimerEnabled, function(value)
        Config.TimerEnabled = value

        if Config.TimerEnabled then
            if Config.DesyncEnabled then
                startTimerLoop()
            else
                UI.SetValue("TimerToggle", false)
                Config.TimerEnabled = false
            end
        else
            loop_running = false
        end
    end)
    main_sec:Tip("Automatically restarts desync at the interval below (causes teleport effect).")

    main_sec:SliderInt("TimerInterval", "Toggle Interval (seconds)", 1, 60, Config.TimerInterval, function(value)
        Config.TimerInterval = value

        if Config.TimerEnabled then
            startTimerLoop()
        end
    end)
    main_sec:Tip("Time between desync restarts (off -> on instantly).")
end)

task_spawn(function()
    local lastDead = false

    while true do
        task_wait(0.2)

        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        if not lp then continue end

        local char = lp.Character
        if not char then continue end

        local hum = char:FindFirstChild("Humanoid")
        if not hum then continue end

        local ok, health = pcall(function() return hum.Health end)
        if not ok or not health then continue end

        if health <= 0 then
            lastDead = true
        elseif lastDead then
            lastDead = false

            task_wait(1)
            base_address = getbase()

            if Config.DesyncEnabled then
                startWriteLoop()

                if Config.TimerEnabled then
                    startTimerLoop()
                end
            end
        end
    end
end)

task_spawn(function()
    task_wait(0.1)
    UI.SetValue("DesyncToggle", Config.DesyncEnabled)
    UI.SetValue("TimerToggle", Config.TimerEnabled)
    UI.SetValue("TimerInterval", Config.TimerInterval)
end)

print("Desync by bubzie loaded. Ensure 'Unsafe LuaU' is enabled.")
warn("may not work too well, im not too sure whether auto toggle works or not idk much about luau sorry :<")
warn("i also think it breaks if you die, so uh yeah idk maybe a more experienced scripter can fix this")
