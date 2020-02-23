using CoordinateTransformations
import Base.convert

struct MoebiusTrans{T} <: Transformation
    a::T
    b::T
    c::T
    d::T
end

Base.inv(mo ::MoebiusTrans) = MoebiusTrans(mo.d, -mo.b, -mo.c, mo.a)

function (mo::MoebiusTrans{T})(z) where {T}
    (mo.a * z + mo.b) / (mo.c * z + mo.d)
end

struct NormalTrans{T} <: Transformation
    p::T
    q::T
    λ::T
end

Base.inv(mo ::NormalTrans) = NormalTrans(mo.q, mo.p, mo.λ)
inv_(mo ::NormalTrans) = NormalTrans(mo.p, mo.q, mo.λ^-1)

function (mo::NormalTrans{T})(z) where {T}
    convert(MoebiusTrans, mo)(z)
end

convert(::Type{MoebiusTrans}, mo::NormalTrans) = MoebiusTrans(
    mo.p - mo.λ * mo.q,
    mo.p * mo.q * (mo.λ - 1),
    1 - mo.λ,
    mo.λ * mo.p - mo.q
)


function testclass(TheClass, ParsType, npar; niter=100)
    maximum(1:niter) do _
        mo = TheClass(randn(ParsType, npar)...)
        zz = randn(ParsType)

        forward_rez = inv(mo)(mo(zz)) - zz
        reverse_rez = mo(inv(mo)(zz)) - zz

        maximum(abs.((forward_rez, reverse_rez)))
    end
end

function testconv(; niter=10000)
    maximum(1:niter) do _
        mo = NormalTrans(randn(Complex{Float64}, 3)...)
        zz = randn(Complex{Float64})

        fa = mo(zz)
        fb = convert(MoebiusTrans, mo)(zz)

        abs(fa - fb)
    end
end


@assert testclass(MoebiusTrans, Complex{Float64}, 4) < 3e-13
@assert testclass(NormalTrans, Complex{Float64}, 3) < 3e-13
@assert testconv() < 1e-11
