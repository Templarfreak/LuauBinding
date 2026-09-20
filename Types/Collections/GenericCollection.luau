--!strict
export type GenericCollection<T> = {
    length: () -> (number)
}

export type SequentialCollection<T> = GenericCollection<T> & {
    [number]: T,
}

export type AssociativeCollection<K, V> = GenericCollection<V> & {
    [K]: V,
}

return {}