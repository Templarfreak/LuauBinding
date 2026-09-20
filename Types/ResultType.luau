--!strict
export type Ok<T> = {value: T}
export type Err<T> = {Err: T}

export type Result<T, E> = {
    result: Ok<T> | Err<E>
}

local result_type = {};

result_type.Ok = function<T, E>(value: T): Result<T, E>
    local result: Result<T, E> = { result = { value = value }}
    return result
end

result_type.Err = function<T, E>(error: E): Result<T, E>
    local result: Result<T, E> = { result = { Err = error }}
    return result
end

return result_type