length_local(x::Union{<:PencilArray, <:GlobalPencilArray}) = length(parent(x))

"""
    size(x::PencilArray)

Return global dimensions of a `PencilArray` in logical order.

Defined as `size_global(x, LogicalOrder())`.
"""
Base.size(x::Union{<:PencilArray, <:GlobalPencilArray}) =
    size_global(x, LogicalOrder())

"""
    length(x::PencilArray)

Get the *global* number of elements stored in the `PencilArray`.
"""
Base.length(x::Union{<:PencilArray, <:GlobalPencilArray}) = prod(size(x))

# By default, eachindex calls length(x) in this case.
# Since length returns the *global* length, we override it to return an iterator
# over the *local* length.
Base.eachindex(::IndexLinear, x::Union{<:PencilArray, <:GlobalPencilArray}) =
    Base.OneTo(length_local(x))

"""
    size_local(x::PencilArray, [order = LogicalOrder()])
    size_local(x::PencilArrayCollection, [order = LogicalOrder()])

Local dimensions of the data held by the `PencilArray`.

See also [`size_local(::Pencil)`](@ref).
"""
size_local(x::MaybePencilArrayCollection, args...; kwargs...) =
    (size_local(pencil(x), args...; kwargs...)..., extra_dims(x)...)

size_local(x::GlobalPencilArray, args...; kwargs...) =
    size_local(parent(x), args...; kwargs...)

"""
    size_global(x::PencilArray, [order = LogicalOrder()])
    size_global(x::PencilArrayCollection, [order = LogicalOrder()])

Global dimensions associated to the given array.

By default, the logical dimensions of the dataset are returned.

If `order = LogicalOrder()`, this is the same as `size(x)`.

See also [`size_global(::Pencil)`](@ref).
"""
size_global(x::MaybePencilArrayCollection, args...; kw...) =
    (size_global(pencil(x), args...; kw...)..., extra_dims(x)...)

size_global(x::GlobalPencilArray, args...; kwargs...) =
    size_global(parent(x), args...; kwargs...)
