"""
    ManyPencilArray{T,N,M}

Container holding `M` different [`PencilArray`](@ref) views to the same
underlying data buffer. All views share the same element type `T` and
dimensionality `N`.

This can be used to perform in-place data transpositions with
[`transpose!`](@ref Transpositions.transpose!).

---

    ManyPencilArray{T}(undef, pencils...; extra_dims=())

Create a `ManyPencilArray` container that can hold data of type `T` associated
to all the given [`Pencil`](@ref)s.

The optional `extra_dims` argument is the same as for [`PencilArray`](@ref).
"""
struct ManyPencilArray{
        T,  # element type of each array
        N,  # number of dimensions of each array (including extra_dims)
        M,  # number of arrays
        Arrays <: Tuple{Vararg{PencilArray,M}},
    }
    data :: Vector{T}
    arrays :: Arrays

    function ManyPencilArray{T}(
            init, pencils::Vararg{Pencil{Np},M};
            extra_dims::Dims=(),
        ) where {Np,M,T}
        data_length = max(length.(pencils)...) * prod(extra_dims)
        data = Vector{T}(init, data_length)
        arrays = _make_arrays(data, extra_dims, pencils...)
        A = typeof(arrays)
        N = Np + length(extra_dims)
        new{T,N,M,A}(data, arrays)
    end
end

function _make_arrays(data::Vector{T}, extra_dims::Dims, p::Pencil,
                      pens::Vararg{Pencil}) where {T}
    dims = (size_local(p, MemoryOrder())..., extra_dims...)
    n = prod(dims)
    @assert n == length_local(p) * prod(extra_dims)
    vec = view(data, Base.OneTo(n))
    arr = reshape(vec, dims)
    A = PencilArray(p, arr)
    (A, _make_arrays(data, extra_dims, pens...)...)
end

_make_arrays(::Vector, ::Dims) = ()

Base.eltype(A::ManyPencilArray{T}) where {T} = T
Base.ndims(A::ManyPencilArray{T,N}) where {T,N} = N

"""
    length(A::ManyPencilArray)

Returns the number of [`PencilArray`](@ref)s wrapped by `A`.
"""
Base.length(A::ManyPencilArray{T,N,M}) where {T,N,M} = M

"""
    first(A::ManyPencilArray)

Returns the first [`PencilArray`](@ref) wrapped by `A`.
"""
Base.first(A::ManyPencilArray) = first(A.arrays)

"""
    last(A::ManyPencilArray)

Returns the last [`PencilArray`](@ref) wrapped by `A`.
"""
Base.last(A::ManyPencilArray) = last(A.arrays)

"""
    getindex(A::ManyPencilArray, ::Val{i})
    getindex(A::ManyPencilArray, i::Integer)

Returns the i-th [`PencilArray`](@ref) wrapped by `A`.

If possible, the `Val{i}` form should be preferred, as it is more efficient and
it allows the compiler to know the return type.

See also [`first(::ManyPencilArray)`](@ref), [`last(::ManyPencilArray)`](@ref).

# Example

```julia
A = ManyPencilArray(pencil1, pencil2, pencil3)

# Get the PencilArray associated to `pencil2`.
# u2 = A[2]
u2 = A[Val(2)]  # faster!
```
"""
Base.getindex(A::ManyPencilArray, ::Val{i}) where {i} =
    _getindex(Val(i), A.arrays...)
@inline Base.getindex(A::ManyPencilArray, i) = A[Val(i)]

@inline function _getindex(::Val{i}, a, t::Vararg) where {i}
    i :: Integer
    i <= 0 && throw(BoundsError("index must be >= 1"))
    i == 1 && return a
    _getindex(Val(i - 1), t...)
end

# This will happen if the index `i` intially passed is too large.
@inline _getindex(::Val) = throw(BoundsError("invalid index"))
