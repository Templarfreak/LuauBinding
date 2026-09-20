--!strict
local list_table = require("Collections/list")
local generic_function = require("GenericFunction")
type list<T> = list_table.list<T>
type generic_function = generic_function.generic_function

-- TODO: implement actual clock
local current_time = 0

export type Timer = {
    -- fields
    start_time: number,
    duration: number,
    end_time: number,
    pause_time: number,
    repeating: boolean,
    done: boolean,
    started: boolean,
    paused: boolean,
    callbacks: list<generic_function> | nil,

    -- methods
    elapsed_time: () -> number,
    remaining_time: () -> number,
    stop_timer: () -> (),
    start_timer: (dur: number, repeating: boolean, start_time: number, callback: list<generic_function> | generic_function?) -> (),
    pause_timer: () -> (),
    unpause_timer: () -> ()
}

local Timer = {}

function Timer.GetElapsedTime(timer_inst: Timer): number
    return math.min(current_time - timer_inst.start_time, timer_inst.duration)
end

    
function Timer.GetRemainingTime(timer_inst: Timer): number
    return timer_inst.duration - Timer.GetElapsedTime(timer_inst)
end

function Timer.StopTimer(timer_inst: Timer)
    local elapsed_time = Timer.GetElapsedTime(timer_inst)
    timer_inst.done = true
    timer_inst.repeating = false
    timer_inst.started = false
    timer_inst.paused = false

    return elapsed_time
end

function Timer.StartTimer(timer_inst: Timer, duration: number, enable_repeat: boolean, start_time: number, callbacks: list<generic_function> | generic_function?)
    local time = current_time
    timer_inst.start_time = start_time or time
    timer_inst.duration = duration
    timer_inst.end_time = timer_inst.start_time + duration
    timer_inst.callbacks = nil

    timer_inst.repeating = enable_repeat
    timer_inst.done = false
    timer_inst.started = true
    timer_inst.paused = false

    if (type(callbacks) == "table") then
        timer_inst.callbacks = list_table.new({table.unpack(callbacks)})
    elseif (type(callbacks) == "function") then
        timer_inst.callbacks = list_table.new(callbacks)
    end
end

function Timer.PauseTimer(timer_inst: Timer)
    timer_inst.pause_time = current_time
    timer_inst.paused = true
end

function Timer.UnpauseTimer(timer_inst: Timer)
    timer_inst.end_time = timer_inst.end_time + (current_time - (timer_inst.pause_time + current_time))
    timer_inst.paused = false
end

function Timer.NewTimer(): Timer
    local t: Timer
    t = {   
        start_time = 0,
        duration = 0,
        end_time = 0,
        pause_time = 0,
        repeating = false,
        done = false,
        started = false,
        paused = false,
        callback = nil,

        elapsed_time = function() return Timer.GetElapsedTime(t) end,
        remaining_time = function() return Timer.GetRemainingTime(t) end,
        stop_timer = function() Timer.StopTimer(t) end,

        start_timer = function(dur: number, repeating: boolean, start_time: number, callbacks: list<generic_function> | generic_function?) 
            Timer.StartTimer(t, dur, repeating, start_time, callbacks)
        end,

        pause_timer = function() Timer.PauseTimer(t) end,
        unpause_timer = function() Timer.UnpauseTimer(t) end
    }

    return t
end

return Timer