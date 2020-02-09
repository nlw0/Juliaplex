using Images
using PerceptualColourMaps
using CoordinateTransformations
using LinearAlgebra

using StaticArrays
using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer

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

    ff=1

    ww = rand(21) .+ 0.5
    vv = rand(21) .+ 0.5

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

        # SDL2.RenderCopy(renderer, texture, C_NULL, C_NULL)

        # SDL2.SetRenderDrawColor(renderer, 255, 255, 255, SDL2.ALPHA_OPAQUE);
        # SDL2.RenderDrawLine(renderer, 320, 200, 300, 240);
        # SDL2.RenderDrawLine(renderer, 300, 240, 340, 240);
        # SDL2.RenderDrawLine(renderer, 340, 240, 320, 200);

        for (w,v) in zip(ww,vv)
            t1 = sin(w * ff/200)
            s1 = π * (sin(v*ff/150))
            render_hyp!(renderer, (K,J), s1, t1)
        end


        SDL2.RenderPresent(renderer)
        sleep(0.0)

        ff += 1
    end

    SDL2.Quit()
end

function render_hyp!(renderer, (K,J), s,t)
    cam = AffineMap([500 0; 0 500], [K,J]/2)

    SDL2.SetRenderDrawColor(renderer, 255, 255, 255, SDL2.ALPHA_OPAQUE);

    R = RotMatrix(2*π/1001)

    x1 = SVector(0.0,1.0)
    p1 = round.(Int, cam(x1))
    for n in 1:1100
        x2 = R * x1
        p2 = round.(Int, cam(x2))
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
        x1 = x2
        p1 = p2
        if norm(x2) >1
            break
        end
    end

    θ = atan((1-t^2)/(t^2+1), (2*t)/(t^2+1))
    r = tan(θ)

    N = ceil(Int, (π/2-θ)*r/0.01)
    ll = (π/2-θ)*r/N
    α = (π/2-θ)/N

    T1 = LinearMap(RotMatrix(s)) ∘ Translation(SVector(0,t))
    T2 = T1 ∘ LinearMap([-1 0;0 1])

    R = RotMatrix(α)

    delta = RotMatrix(α/2)*SVector(1.0,0.0)
    delta = ll * delta / norm(delta)

    x1 = SVector(0.0,0.0)
    p1 = round.(Int, (cam∘T1)(x1))
    p1i = round.(Int, (cam∘T2)(x1))
    for n in 1:N
        x2 = x1 + delta
        delta  = R * delta
        p2 = round.(Int, (cam∘T1)(x2))
        p2i = round.(Int, (cam∘T2)(x2))
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
        SDL2.RenderDrawLine(renderer, p1i[1], p1i[2], p2i[1], p2i[2])
        # SDL2.RenderDrawPoint(renderer, Int32(p1[1]), Int32(p1[2] - 2))
        x1 = x2
        p1 = p2
        p1i = p2i
    end

end

function render_cube!(renderer, (K,J), ff)
    cam = AffineMap([500 0; 0 500], [K,J]/2)

    θ = 2*π* [sin(ff/200+1.0),sin(2*ff/200),sin(ff/2/200)]
    R = RodriguesVec(θ...)

    cube = hcat([[x,y,z] for x in [-1,1], y in [-1,1], z in [-1,1]]...)

    rc = map(eachcol(cube)) do v
        vr = (cam ∘ PerspectiveMap() ∘ Translation([0,0,5]))(R * v)
        round.(Int, vr)
    end

    SDL2.SetRenderDrawColor(renderer, 255, 255, 255, SDL2.ALPHA_OPAQUE);
    for (ea,eb) in [(1,2), (1,3), (1,5), (2,4), (2,6), (3,4),
                    (3,7), (4,8), (5,6), (5,7), (6,8), (7,8)]
        p1 = rc[ea]
        p2 = rc[eb]
        SDL2.RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2])
    end

end

function render_px!(pixels, (K,J), ff)
    (K,J) = size(pixels)
    pixels[1+ff%K,1+ff%J] = convert(ARGB32, RGB(0.2,0.5,0.9)).color
end

# main(Val(1023))
# main(Val(511))
main(Val(255))
# main(Val(127))
# main(Val(63))
# main(Val(31))
