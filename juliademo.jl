using Images
using PerceptualColourMaps

using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer

using SimpleDirectMediaLayer.LibSDL2


include("juliaset.jl")

function main(::Val{Maxiter}) where Maxiter

    # SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
    # SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 16)
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)

    # SDL2.init()

    # K=200;J=150
    # K=400;J=300
    # K=800;J=600
    K=1920;J=1080

    win = SDL_CreateWindow(
        "Juliaplex",
        Int32(0),
        Int32(0),
        Int32(K),
        Int32(J),
        UInt32(SDL_WINDOW_SHOWN)
    )
    SDL_SetWindowResizable(win, SDL_bool(true))

    renderer = SDL_CreateRenderer(
        win,
        Int32(-1),
        UInt32(SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    )

    texture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_ARGB8888,
        Int32(SDL_TEXTUREACCESS_STATIC),
        Int32(K),
        Int32(J)
    )

    pixels = zeros(UInt32, K, J)


    # cmap = map(colormap("Blues", Maxiter)) do aa
    # cmap = map(colormap("Oranges", 50 + 1)) do aa
    # cmap = map(colormap("RdBu", Maxiter)) do aa
        # convert(ARGB32,aa).color
    # end

    F = 64*24
    # cinc = Float32(cos(2*pi/F)) + Float32(sin(2*pi/F))im
    # c = 1.0f0 + 0.0f0 * im
    cinc = cos(2*pi/F) + sin(2*pi/F)im
    c = 1.0 + 0.0 * im

    cm = map(cmap("C1";N=Maxiter)) do aa
        convert(ARGB32,aa).color
    end
    # cm2 = map(cmap("C2";N=Maxiter)) do aa
        # convert(ARGB32,aa).color
    # end
    # cm3 = map(cmap("C3";N=Maxiter)) do aa
        # convert(ARGB32,aa).color
    # end

    ff=1
    while true
        SDL_PumpEvents()

        # x,y = SDL2.mouse_position()
        # c = exp(Float32(( (x - 1920/2) / 10 + 1920/2 )*2*pi/1920 ) * im)
        # cm = map(cmap("R1";N=Maxiter)) do aa
            # convert(ARGB32,aa).color
        # end
        # aa = div(y * 31, 1080) + 1
        # cm = vcat(cm[aa:Maxiter], cm[1: aa])

        aa = floor(Int64, ((ff+1000)*0.001))%(Maxiter-1) +1
        cm = vcat(cm[aa:Maxiter], cm[1: aa])

        nf=512
        # nf=256
        # nf=128
        f = (ff % div(nf, 4))+2
        g = Float32(((nf-(nf+f)/f)/nf)^0.5)
        c = exp(g * 0.925 * pi * im)

        # c *= cinc

        # c = -1.5
        # c = im
        # c =-0.75+0.11*im
        # c = exp((0.5pi + 0.1/3)*im)
        # c = im#exp(0.5pi*im)


        event_ref = Ref{SDL_Event}()
        SDL_PollEvent(event_ref)
        evt = event_ref[]

        if evt.type == SDL_QUIT
            @info "CLOSE!"
            break
        # end
        elseif evt.type == SDL_MOUSEBUTTONDOWN
            # @show evt.button.button
            @show c
        end

        render_julia_set!(pixels, c, K, J, Val(Maxiter), Val(8), cm)

        SDL_UpdateTexture(texture, C_NULL, pointer(pixels), Int32(K * sizeof(UInt32)));

        SDL_PumpEvents()
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
        SDL_RenderClear(renderer)
        SDL_RenderCopy(renderer, texture, C_NULL, C_NULL)
        SDL_RenderPresent(renderer)
        sleep(0.0)

        ff += 1
    end

    SDL_Quit()
end

# main(Val(1023))
# main(Val(511))
main(Val(255))
# main(Val(127))
# main(Val(63))
# main(Val(31))
