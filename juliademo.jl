using Images
using PerceptualColourMaps

using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer

include("juliaset.jl")

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
        SDL2.PumpEvents()

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

        ev = SDL2.event()
        if typeof(ev) == SDL2.WindowEvent && ev.event == SDL2.WINDOWEVENT_CLOSE
            @show "CLOSE!", ev
            break
        elseif typeof(ev) == SDL2.MouseButtonEvent && ev.button==0x01 && ev.state == 0x01
            @show c
        end

        render_julia_set!(pixels, c, K, J, Val(Maxiter), Val(8), cm)

        SDL2.UpdateTexture(texture, C_NULL, pointer(pixels), Int32(K * sizeof(UInt32)));

        SDL2.PumpEvents()
        SDL2.SetRenderDrawColor(renderer, 0, 0, 0, 255)
        SDL2.RenderClear(renderer)
        SDL2.RenderCopy(renderer, texture, C_NULL, C_NULL)
        SDL2.RenderPresent(renderer)
        sleep(0.0)

        ff += 1
    end

    SDL2.Quit()
end

# main(Val(1023))
# main(Val(511))
main(Val(255))
# main(Val(127))
# main(Val(63))
# main(Val(31))
