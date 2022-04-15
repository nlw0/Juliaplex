using Images
using PerceptualColourMaps
using CoordinateTransformations
using LinearAlgebra

using StaticArrays
using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer

include("moeb.jl")

function main(::Val{Maxiter}) where Maxiter

    SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
    SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

    SDL2.init()

    # K=200;J=150
    # K=400;J=300
    # K=800;J=600
    K=1920;J=1080

    win = SDL2.CreateWindow(
        "Juliaplex",
        Int32(0),
        Int32(0),
        Int32(K),
        Int32(J),
        UInt32(SDL2.WINDOW_SHOWN)
    )
    SDL2.SetWindowResizable(win,true)

    renderer = SDL2.CreateRenderer(
        win,
        Int32(-1),
        UInt32(SDL2.RENDERER_ACCELERATED | SDL2.RENDERER_PRESENTVSYNC)
    )

    texture = SDL2.CreateTexture(
        renderer,
        SDL2.PIXELFORMAT_ARGB8888,
        Int32(SDL2.TEXTUREACCESS_STATIC),
        Int32(K),
        Int32(J)
    )

    pixels = zeros(UInt32, K, J)


    F = 64*24
    # cinc = Float32(cos(2*pi/F)) + Float32(sin(2*pi/F))im
    # c = 1.0f0 + 0.0f0 * im
    cinc = cos(2*pi/F) + sin(2*pi/F)im
    c = 1.0 + 0.0 * im

    cm = map(cmap("C1";N=Maxiter)) do aa
        convert(ARGB32,aa).color
    end

    ff = 1

    w1 = rand() .+ 0.5
    v1 = rand() .+ 0.5
    w2 = rand() .+ 0.5
    v2 = rand() .+ 0.5

    xx = rand(64).^0.5 .* exp.(im * 2*π * rand(64))

    while true
        SDL2.PumpEvents()

        ev = SDL2.event()
        if typeof(ev) == SDL2.WindowEvent && ev.event == SDL2.WINDOWEVENT_CLOSE
            @show "CLOSE!", ev
            break
        elseif typeof(ev) == SDL2.MouseButtonEvent && ev.button==0x01 && ev.state == 0x01
            @show ff
        end

        SDL2.UpdateTexture(texture, C_NULL, pointer(pixels), Int32(K * sizeof(UInt32)));

        SDL2.PumpEvents()
        SDL2.SetRenderDrawColor(renderer, 0, 0, 0, SDL2.ALPHA_OPAQUE);
        SDL2.RenderClear(renderer);

        render_unitcirc!(renderer, (K,J))

        t1 = sin(w1 * ff/200)
        s1 = π * (sin(v1 * ff/150))
        p1 = t1 * exp(im * s1)
        t2 = sin(w2 * ff/200)
        s2 = π * (sin(v2 * ff/150))
        p2 = t2 * exp(im * s2)

        for x in xx
            render_mo!(renderer, (K,J), p1,p2, x)
        end

        SDL2.RenderPresent(renderer)
        sleep(0.0)

        ff += 1
    end

    SDL2.Quit()
end

function render_unitcirc!(renderer, (K,J))
    cam = AffineMap([500 0; 0 500], [K,J]/2)

    SDL2.SetRenderDrawColor(renderer, 255, 255, 255, SDL2.ALPHA_OPAQUE);

    R = RotMatrix(2*π/1001)

    x2 = SVector(0.0,1.0)
    p2 = round.(Int, cam(x2))
    for n in 1:1100
        x1 = x2
        p1 = p2
        x2 = R * x1
        p2 = round.(Int, cam(x2))
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
        if norm(x2) >1
            break
        end
    end
end

imto2d(x) = SVector(real(x), imag(x))

function render_mo!(renderer, (K,J), q1,q2, x2)
    mo = NormalTrans(q1, q2, 0.97 + 0.02im)

    cam = AffineMap([500 0; 0 500], [K,J]/2)

    imo = inv(mo)
    x2i = x2
    p2 = round.(Int, cam(imto2d(x2)))
    p2i = round.(Int, cam(imto2d(x2i)))
    N = 44

    ip2 = p2

    SDL2.SetRenderDrawColor(renderer, 200, 200, 200, SDL2.ALPHA_OPAQUE);
    for n in 1:N
        x1 = x2
        p1 = p2
        x1i = x2i
        p1i = p2i

        x2 = mo(x1)
        x2i = imo(x1i)

        p2 = round.(Int, cam(imto2d(x2)))
        p2i = round.(Int, cam(imto2d(x2i)))
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
        SDL2.RenderDrawLine(renderer, p1i[1], p1i[2], p2i[1], p2i[2])
    end

    SDL2.SetRenderDrawColor(renderer, 255, 33, 33, SDL2.ALPHA_OPAQUE);
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]+1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]-1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]+1), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]-1), Int32(ip2[2]))

    ip2 = round.(Int, cam(imto2d(q1)))

    SDL2.SetRenderDrawColor(renderer, 33, 33, 255, SDL2.ALPHA_OPAQUE);
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]+1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]-1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]+1), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]-1), Int32(ip2[2]))

    ip2 = round.(Int, cam(imto2d(q2)))

    SDL2.SetRenderDrawColor(renderer, 33, 33, 255, SDL2.ALPHA_OPAQUE);
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]+1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]), Int32(ip2[2]-1))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]+1), Int32(ip2[2]))
    SDL2.RenderDrawPoint(renderer, Int32(ip2[1]-1), Int32(ip2[2]))

end

function render_cline!(renderer, (K,J), s,t)
    cam = AffineMap([500 0; 0 500], [K,J]/2)

    SDL2.SetRenderDrawColor(renderer, 255, 255, 255, SDL2.ALPHA_OPAQUE);

    θ = atan((1-t^2)/(t^2+1), (2*t)/(t^2+1))
    r = tan(θ)

    N = ceil(Int, (π/2-θ)*r/0.01)
    ll = (π/2-θ)*r/N
    α = (π/2-θ)/N

    T1 = LinearMap(RotMatrix(s)) ∘ Translation(SVector(0,t))
    T2 = T1 ∘ LinearMap([-1 0;0 1])

    R = RotMatrix(α)

    delta = RotMatrix(-α/2)*SVector(1.0,0.0)
    delta = ll * delta / norm(delta)

    x2 = SVector(0.0,0.0)
    p2 = round.(Int, (cam∘T1)(x2))
    p2i = round.(Int, (cam∘T2)(x2))
    for n in 1:N
        x1 = x2
        p1 = p2
        p1i = p2i
        delta = R * delta
        x2 = x1 + delta
        p2 = round.(Int, (cam∘T1)(x2))
        p2i = round.(Int, (cam∘T2)(x2))
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
        SDL2.RenderDrawLine(renderer, p1i[1], p1i[2], p2i[1], p2i[2])
    end

end

# main(Val(1023))
# main(Val(511))
main(Val(255))
# main(Val(127))
# main(Val(63))
# main(Val(31))
