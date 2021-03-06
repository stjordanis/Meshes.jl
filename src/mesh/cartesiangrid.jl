# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    CartesianGrid(dims, origin, spacing)

A Cartesian grid with dimensions `dims`, lower left corner at `origin`
and cell spacing `spacing`. The three arguments must have the same length.

    CartesianGrid(start, finish, dims=dims)

Alternatively, construct a Cartesian grid from a `start` point (lower left)
to a `finish` point (upper right).

    CartesianGrid{T}(dims)
    CartesianGrid{T}(dim1, dim2, ...)

Finally, a Cartesian grid can be constructed by only passing the dimensions
`dims` as a tuple, or by passing each dimension `dim1`, `dim2`, ... separately.
In this case, the origin and spacing default to (0,0,...) and (1,1,...).

## Examples

Create a 3D grid with 100x100x50 locations:

```julia
julia> CartesianGrid(100,100,50)
```

Create a 2D grid with 100x100 locations and origin at (10.,20.) units:

```julia
julia> CartesianGrid((100,100),(10.,20.),(1.,1.))
```

Create a 1D grid from -1 to 1 with 100 locations:

```julia
julia> CartesianGrid((-1.,),(1.,), dims=(100,))
```
"""
struct CartesianGrid{Dim,T} <: Mesh{Dim,T}
  dims::Dims{Dim}
  origin::Point{Dim,T}
  spacing::SVector{Dim,T}

  function CartesianGrid{Dim,T}(dims, origin, spacing) where {Dim,T}
    @assert all(dims .> 0) "dimensions must be positive"
    @assert all(spacing .> 0) "spacing must be positive"
    new(dims, origin, spacing)
  end
end

CartesianGrid(dims::Dims{Dim}, origin::Point{Dim,T}, spacing::SVector{Dim,T}) where {Dim,T} =
  CartesianGrid{Dim,T}(dims, origin, spacing)

CartesianGrid(dims::Dims{Dim}, origin::NTuple{Dim,T}, spacing::NTuple{Dim,T}) where {Dim,T} =
  CartesianGrid{Dim,T}(dims, Point(origin), SVector(spacing))

CartesianGrid(start::Point{Dim,T}, finish::Point{Dim,T};
              dims::Dims{Dim}=ntuple(i->100, Dim)) where {Dim,T} =
  CartesianGrid{Dim,T}(dims, start, (finish - start) ./ dims)

CartesianGrid(start::NTuple{Dim,T}, finish::NTuple{Dim,T};
              dims::Dims{Dim}=ntuple(i->100, Dim)) where {Dim,T} =
  CartesianGrid(Point(start), Point(finish); dims=dims)

CartesianGrid{T}(dims::Dims{Dim}) where {Dim,T} =
  CartesianGrid{Dim,T}(dims, ntuple(i->zero(T), Dim), ntuple(i->one(T), Dim))

CartesianGrid{T}(dims::Vararg{Int,Dim}) where {Dim,T} = CartesianGrid{T}(dims)

CartesianGrid(dims::Dims{Dim}) where {Dim} = CartesianGrid{Float64}(dims)

CartesianGrid(dims::Vararg{Int,Dim}) where {Dim} = CartesianGrid{Float64}(dims)

Base.size(g::CartesianGrid) = g.dims
Base.minimum(g::CartesianGrid) = g.origin
Base.maximum(g::CartesianGrid) = g.origin + g.dims .* g.spacing
spacing(g::CartesianGrid) = g.spacing

function vertices(g::CartesianGrid)
  inds = CartesianIndices(g.dims .+ 1)
  ivec(g.origin + (ind.I .- 1) .* g.spacing for ind in inds)
end

function elements(g::CartesianGrid{Dim,T}) where {Dim,T}
  o = coordinates(g.origin)
  s = g.spacing

  inds = CartesianIndices(g.dims)
  function element(ind)
    i = ind.I
    if Dim == 1 # segment
      p1 = (o[1] + (i[1] - 1) * s[1],)
      p2 = (o[1] + (    i[1]) * s[1],)
      Segment(p1, p2)
    elseif Dim == 2 # quadrangle
      p1 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2] - 1) * s[2])
      p2 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2] - 1) * s[2])
      p3 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2]    ) * s[2])
      p4 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2]    ) * s[2])
      Quadrangle(p1, p2, p3, p4)
    elseif Dim == 3 # hexahedron
      p1 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2] - 1) * s[2],
            o[3] + (i[3] - 1) * s[3])
      p2 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2] - 1) * s[2],
            o[3] + (i[3] - 1) * s[3])
      p3 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2]    ) * s[2],
            o[3] + (i[3] - 1) * s[3])
      p4 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2]    ) * s[2],
            o[3] + (i[3] - 1) * s[3])
      p5 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2] - 1) * s[2],
            o[3] + (i[3]    ) * s[3])
      p6 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2] - 1) * s[2],
            o[3] + (i[3]    ) * s[3])
      p7 = (o[1] + (i[1]    ) * s[1],
            o[2] + (i[2]    ) * s[2],
            o[3] + (i[3] - 1) * s[3])
      p8 = (o[1] + (i[1] - 1) * s[1],
            o[2] + (i[2]    ) * s[2],
            o[3] + (i[3]    ) * s[3])
      Hexahedron(p1, p2, p3, p4, p5, p6, p7, p8)
    else
      @error "not implemented"
    end
  end
  ivec(element(ind) for ind in inds)
end

function Base.show(io::IO, g::CartesianGrid{Dim,T}) where {Dim,T}
  dims = join(g.dims, "×")
  print(io, "$dims CartesianGrid($(minimum(g)), $(maximum(g)))")
end

function Base.show(io::IO, ::MIME"text/plain", g::CartesianGrid{Dim,T}) where {Dim,T}
  dims = join(g.dims, "×")
  println(io, "$dims CartesianGrid{$Dim,$T}")
  println(io, "  minimum: ", minimum(g))
  println(io, "  maximum: ", maximum(g))
  print(  io, "  spacing: ", Tuple(spacing(g)))
end
