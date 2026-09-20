local arr = require("../Collections/array")
local l = require("../Collections/list")

type array<T> = arr.array<T>
type list<T> = l.list<T>

export type GenericTrait = {
    owner: GenericObject,
    init: (owner: GenericObject) -> ()
}

export type GenericObject = {
    traits: array<list<GenericTrait>>,
    add_trait: (t: GenericTrait) -> (),
    init_trait: () -> (),
    get_trait_at: <T>(index: number) -> (T),
    get_trait: <T>() -> (T),
    has_trait: <T>() -> (T)
}