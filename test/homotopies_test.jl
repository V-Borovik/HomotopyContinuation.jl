@testset "Homotopies" begin
    @testset "ParameterHomotopy" begin
        @var x y a b c

        f = [(2 * x^2 + b^2 * y^3 + 2 * a * x * y)^3, (a + c)^4 * x + y^2]
        F = System(f, [x, y], [a, b, c])

        p = [5.2, -1.3, 9.3]
        q = [2.6, 3.3, 2.3]

        H = HC2.ParameterHomotopy(F, p, q)

        v = [0.192, 2.21]
        t = 0.232

        u = zeros(ComplexF64, 2)
        U = zeros(ComplexF64, 2, 2)

        HC2.evaluate!(u, H, v, t)
        @test u ≈ f([x, y] => v, [a, b, c] => t * p + (1 - t) * q)

        HC2.taylor!(u, Val(1), H, TaylorVector{1}(Matrix(v')), t)
        @test u ≈ let
            @var s sp[1:3] sq[1:3]
            pt = s .* sp .+ (1 .- s) .* sq
            differentiate(subs(f, [a, b, c] => pt), s)(
                [x, y] => v,
                sp => p,
                sq => q,
                s => t,
            )
        end

        HC2.evaluate_and_jacobian!(u, U, H, v, t)
        @test U ≈ differentiate(f, [x, y])(
            [x, y] => v,
            [a, b, c] => t * p + (1 - t) * q,
        )
    end

    @testset "ModelKitHomotopy" begin
        @var x y a b c
        f = [(2 * x^2 + b^2 * y^3 + 2 * a * x * y)^3, (a + c)^4 * x + y^2]

        @var s sp[1:3] sq[1:3]
        g = subs(f, [a, b, c] => s .* sp .+ (1 .- s) .* sq)

        H = Homotopy(g, [x, y], s, [sp; sq])

        p = [5.2, -1.3, 9.3]
        q = [2.6, 3.3, 2.3]

        H = HC2.ModelKitHomotopy(H, [p; q])
        @test size(H) == (2, 2)

        v = [0.192, 2.21]
        t = 0.232

        u = zeros(ComplexF64, 2)
        U = zeros(ComplexF64, 2, 2)

        HC2.evaluate!(u, H, v, t)
        @test u ≈ f([x, y] => v, [a, b, c] => t * p + (1 - t) * q)

        HC2.taylor!(u, Val(1), H, TaylorVector{1}(Matrix(v')), t)
        @test u ≈ let
            @var s sp[1:3] sq[1:3]
            pt = s .* sp .+ (1 .- s) .* sq
            differentiate(subs(f, [a, b, c] => pt), s)(
                [x, y] => v,
                sp => p,
                sq => q,
                s => t,
            )
        end

        HC2.evaluate_and_jacobian!(u, U, H, v, t)
        @test U ≈ differentiate(f, [x, y])(
            [x, y] => v,
            [a, b, c] => t * p + (1 - t) * q,
        )

        H = ModelKit.Homotopy(
            [(2 * x^2 + y^3 + 2 * a * y)^3, x + y^2],
            [x, y],
            a,
        )
        @test ModelKitHomotopy(ModelKit.compile(H)) isa ModelKitHomotopy
    end

    @testset "total degree" begin
        @test length(collect(HC2.TotalDegreeStarts([2, 4]))) == 8
        @test length(HC2.TotalDegreeStarts([2, 4])) == 8
        @test eltype(HC2.TotalDegreeStarts([2, 4])) == Vector{ComplexF64}

        @var x y
        F = System([x^2, y^3], [x, y])
        H, starts = total_degree_homotopy(F)
        @test length(starts) == 6
        @var t γ _s_1 _s_2
        @test H isa ModelKitHomotopy
        @test ModelKit.interpret(H.homotopy) == Homotopy(
            [
                x^2 * (1 - t) + t * _s_1 * γ * (-1 + x^2),
                y^3 * (1 - t) + t * _s_2 * γ * (-1 + y^3),
            ],
            [x, y],
            t,
            [γ, _s_1, _s_2],
        )

        @test_throws ArgumentError total_degree_homotopy(System([x + y], [x]))
        @test_throws ArgumentError total_degree_homotopy(System(
            [x + y],
            [x, y],
            [t],
        ))
    end
end
