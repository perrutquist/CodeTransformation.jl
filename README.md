# CodeTransformation

[![Build Status](https://travis-ci.com/perrutquist/CodeTransformation.jl.svg?branch=master)](https://travis-ci.com/perrutquist/CodeTransformation.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/perrutquist/CodeTransformation.jl?svg=true)](https://ci.appveyor.com/project/perrutquist/CodeTransformation-jl)
[![Codecov](https://codecov.io/gh/perrutquist/CodeTransformation.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/perrutquist/CodeTransformation.jl)

This is an experimental package for working with the [`CodeInfo`](https://pkg.julialang.org/docs/julia/THl1k/1.1.1/devdocs/ast.html#CodeInfo-1)
objects that are containded in the vectors that Julia's `code_lowered` and `code_typed` functions return.

These objects can be modified and then turned back into functions (technically methods),
making it possible to apply code transformations to functions defined in other packages,
or in Julia itself.

## Examples

Copy a method from one function to another via a `CodeInfo` object.
```julia
using CodeTransformation
g(x) = x + 13
ci = code_lowered(g)[1] # get the CodeInfo from g's first (and only) method
function f end # create an empty function that we can add a method to
addmethod!(Tuple{typeof(f), Any}, ci)
f(1) # returns 14
```

Search-and-replace in the function `g` from the previous example. (Applies to all
methods, but `g` only has one.)
```julia
function e end
codetransform!(g => e) do ci
    for ex in ci.code
        if ex isa Expr
            map!(x -> x === 13 ? 7 : x, ex.args, ex.args)
        end
    end
    ci
end
e(1) # returns 8
g(1) # still returns 14
```

Note: The syntax may change in the next minor release of this package.
