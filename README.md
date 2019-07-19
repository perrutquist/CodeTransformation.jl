# CodeTransformation

[![Build Status](https://travis-ci.com/perrutquist/CodeTransformation.jl.svg?branch=master)](https://travis-ci.com/perrutquist/CodeTransformation.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/perrutquist/CodeTransformation.jl?svg=true)](https://ci.appveyor.com/project/perrutquist/CodeTransformation-jl)
[![Codecov](https://codecov.io/gh/perrutquist/CodeTransformation.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/perrutquist/CodeTransformation.jl)

Example: Add a method to a function
```
g(x) = x + 13
ci = code_lowered(g)[1]
function f end
addmethod!(Tuple{typeof(f), Any}, ci)
f(1) # returns 14
```

Example: Search-and-replace in a function.
```julia
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
e(1) # returns 8
g(1) # still returns 14
```
