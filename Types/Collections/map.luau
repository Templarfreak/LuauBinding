--!strict
local GenericCollection = require("GenericCollection")

type AssociativeCollection<K, V> = GenericCollection.AssociativeCollection<K, V>

export type map<K, V> = AssociativeCollection<K, V>
return {}