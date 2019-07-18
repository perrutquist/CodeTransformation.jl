# CodeTransformation

[![Build Status](https://travis-ci.com/perrutquist/CodeTransformation.jl.svg?branch=master)](https://travis-ci.com/perrutquist/CodeTransformation.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/perrutquist/CodeTransformation.jl?svg=true)](https://ci.appveyor.com/project/perrutquist/CodeTransformation-jl)
[![Codecov](https://codecov.io/gh/perrutquist/CodeTransformation.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/perrutquist/CodeTransformation.jl)

Example: Replace the constant 13 by 7 in a function.
```
using CodeTransformation

g(x) = x + 13

function e end

codetransform!(g => e) do ci
    for ex in ci.code
        if ex isa Expr
            map!(x -> x === 13 ? 7 : x, ex.args, ex.args)
        end
    end
end
e(1) # returns 8
```
