using CodeTransformation
using Test

@testset "CodeTransformation.jl" begin
    @test CodeTransformation.getmodule(typeof(sin)) === Base
    @test CodeTransformation.getmodule(sin) === Base

    # Test copying CodeInfo from g to e
    g(x) = x + 40
    ci = Base.uncompressed_ast(methods(g).ms[1])
    function e end
    addmethod!(Tuple{typeof(e), Any}, ci)
    @test e(2) === 42

end
