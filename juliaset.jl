using Images
# using Plots
# pyplot()
# using ImageView

using SIMD

using BenchmarkTools
# using Debugger
using Base.Threads

function render_julia_set!(pixels, c::Complex{T}, K, J, ::Val{MaxVal}, ::Val{V}, cmap) where {MaxVal, T, V}
    dx = T(1) / J
    oj = (J+1)/2
    ok = (div(K,V)+1)/2
    vrange = Vec(ntuple(v->T(v), V))
    @threads for j in 1:J
    # for j in 1:J
        for kk in 1:div(K,V)
            zre = T(1.5) * ((((kk-ok-1) * V + vrange) * dx))
            zim = T(1.5) * (one(Vec{V, T}) * (j-oj) * dx)
            ju_itrs = julia_pix(c, zre, zim, Val(MaxVal))
            for v in 1:V
                pixels[(kk-1) * V + v, j] = cmap[ju_itrs[v]]
            end
        end
    end
end

@inline function julia_pix(c::Complex{T}, zre::Vec{V,T}, zim::Vec{V,T}, ::Val{MaxVal}) where {T,MaxVal,V}
    v1 = one(Vec{V, UInt32})
    v0 = zero(Vec{V, UInt32})
    f1 = one(Vec{V, T})
    f0 = zero(Vec{V, T})
    iters = v1
    threshold = T(4) * one(Vec{V,T})
    cre = real(c) * one(Vec{V,T})
    cim = imag(c) * one(Vec{V,T})
    for _ in 1:MaxVal-1
        zabs = zre * zre + zim * zim
        sel = zabs < threshold
        if !any(sel)
            return iters
        end
        # @show zre,zim,zabs, iters,sel
        iters = iters + vifelse(sel, v1, v0)
        zre,zim = vifelse(sel, zre * zre - zim * zim + cre, zre), vifelse(sel, (T(2) * zre * zim) + cim, zim)
    end
    iters
end

function render_julia_set_simple!(pixels, c::Complex{T}, K, J, ::Val{MaxVal}, cmap) where {MaxVal, T}
    rJ = T(1) / J
    rK = T(1) / K
    for j in 1:J, k in 1:K
        z = (((k * rK - T(1/2)) + (j * rJ - T(1/2))im)*T(3))::Complex{T}
        ju_itrs = julia_pix_simple(c, z, Val(MaxVal))
        pixels[k, j] = cmap[ju_itrs]
    end
end

@inline function julia_pix_simple(c::Complex{T}, z, ::Val{MaxVal}) where {T,MaxVal}
    for iteration in 1:MaxVal-1
        # @show z, real(z * z'), iteration
        if real(z * z') >= T(4)
            return iteration
        end
        z = z^2 + c
    end
    MaxVal
end

function bench(::Val{MaxVal}) where MaxVal
    K=1920;J=1080
    pixels = zeros(UInt32, K, J)
    cmap = map(colormap("Blues", MaxVal)) do aa
        convert(ARGB32,aa).color
    end

    # @code_native render_julia_set!(pixels, rand()+rand()im, J,K, Val(51),cmap)
    # @code_warntype render_julia_set!(pixels, rand()+rand()im, J,K, Val(51),cmap)

    # c = Float64(-0.75+0.11)*im # ~ 90ms
    c = (-0.75f0+0.11f0)*im # ~ 90ms
    # c = 0.0f0 + 1.0f0 * im
    # c = im # ~ 20ms
    # c = 1 # ~ 13ms

    render_julia_set_simple!(pixels, c, K, J, Val(MaxVal), cmap)
    bb = @btime render_julia_set_simple!($pixels, $c, $K, $J, $(Val(MaxVal)), $cmap)
    display(bb)
    render_julia_set!(pixels, c, K, J, Val(MaxVal), Val(8), cmap)
    aa = @btime render_julia_set!($pixels, $c, $K, $J, $(Val(MaxVal)), $(Val(8)), $cmap)
    display(aa)
    # @code_native render_julia_set!(pixels, c, J,K, Val(51), cmap)

    # using Profile
    # @profile render_julia_set!(pixels, rand()+rand()im, J,K, Val(51), cmap)
    # Profile.print()
    # @code_warntype julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
    # @code_native julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
    # julia_pix(rand()+rand()im, 100,100,J,K,Val(51))
end

function test(::Val{MaxVal}) where MaxVal
    # K=24; J=16
    K=1920;J=1080
    pixels = zeros(UInt32, K, J)
    cmap = map(colormap("Grays", MaxVal)) do aa
        convert(ARGB32, aa).color
    end

    # c = (-0.75f0+0.11f0)*im # ~ 90ms
    c = 0.0f0 + 1.0f0 * im
    # c = 1.0+0.0im
    render_julia_set!(pixels, c, K, J, Val(MaxVal), Val(8), cmap)
    # render_julia_set_simple!(pixels, c, K, J, Val(MaxVal), cmap)
    heatmap(pixels)
    # plot(colorview(ARGB32,pixels))
    # plot(pixels .+ 0.0, seriestype=:image)
    # pixels
end

# MaxVal = 31
# bench(Val(31))
# aa=test(Val(31))
