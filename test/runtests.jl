using CodeTransformation
using Test

@testset "CodeTransformation.jl" begin
    @test CodeTransformation.getmodule(typeof(sin)) === Base
    @test CodeTransformation.getmodule(sin) === Base

    let
        # Test example from doctring to addmethod!
        g(x) = x + 13
        ci = code_lowered(g)[1]
        function f end
        addmethod!(f, (Any,), ci)
        @test f(1) === 14

        # Alternative syntax
        function f2 end
        @test CodeTransformation.makesig(f2, (Any,)) === Tuple{typeof(f2), Any}
        addmethod!(Tuple{typeof(f2), Any}, ci)
        @test f2(1) === 14

    end

    let
        # Test example from doctring to codetransform!
        g(x) = x + 13
        function e end
        codetransform!(g => e) do ci
            for ex in ci.code
                if ex isa Expr
                    map!(x -> x === 13 ? 7 : x, ex.args, ex.args)
                end
            end
            ci
        end
        @test e(1) === 8
        @test g(1) === 14
    end

    let
        a = Vector{T} where T
        b = CodeTransformation.typevars(a)
        @test b isa Tuple
        @test length(b) == 1
        @test b[1] isa TypeVar
        @test b[1].name == :T
        @test b[1].lb === Union{}
        @test b[1].ub === Any
    end

end
