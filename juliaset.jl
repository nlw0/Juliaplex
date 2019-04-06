using Images
using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer

using BenchmarkTools
using Debugger

function render_julia_set!(pixels, c::Complex{T}, J, K, ::Val{MaxVal}, cmap) where {MaxVal, T}
    rJ = T(1) / J
    rK = T(1) / K
    @inbounds for j in 1:J, k in 1:K
        z = (((k * rK - T(1/2)) + (j * rJ - T(1/2))im)*T(3))::Complex{T}
        ju_itrs = julia_pix(c, z, Val(MaxVal))
        pixels[k, j] = cmap[ju_itrs]
    end
end

@fastmath @inline function julia_pix(c::Complex{T}, z::Complex{T}, ::Val{MaxVal}) where {T,MaxVal}
    for iteration in 1:MaxVal-1
        if real(z * z') >= T(4)
            return iteration
        end
        z = z^2 + c
    end
    MaxVal
end

@fastmath @inline function julia_pix_vec(c::Complex{T}, vz::VComplex{T}, ::Val{MaxVal}) where {T,MaxVal}
    itr =
Vec(ntuple(_->0,8))

    for iteration in 1:MaxVal-1
        if real(z * z') >= T(4)
            return iteration
        end
        z = z^2 + c
    end
    MaxVal
end

function bench(::Val{MaxVal}) where MaxVal
    K=1920; J=1080
    pixels = zeros(UInt32, K, J)
    cmap = map(colormap("Blues", MaxVal)) do aa
        convert(ARGB32,aa).color
    end

    # @code_native render_julia_set!(pixels, rand()+rand()im, J,K, Val(51),cmap)
    # @code_warntype render_julia_set!(pixels, rand()+rand()im, J,K, Val(51),cmap)

    # c = Float64(-0.75+0.11)*im # ~ 90ms
    c = (-0.75f0+0.11f0)*im # ~ 90ms
    # c = im # ~ 20ms
    # c = 1 # ~ 13ms

    render_julia_set!(pixels, c, J,K, Val(MaxVal), cmap)
    aa = @btime render_julia_set!($pixels, $c, $J,$K, $(Val(MaxVal)), $cmap)
    display(aa)
    # @code_native render_julia_set!(pixels, c, J,K, Val(51), cmap)

    # using Profile
    # @profile render_julia_set!(pixels, rand()+rand()im, J,K, Val(51), cmap)
    # Profile.print()
    # @code_warntype julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
    # @code_native julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
    # julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
end

# MaxVal = 31
bench(Val(31))
