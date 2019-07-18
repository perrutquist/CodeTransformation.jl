module CodeTransformation

import Core: SimpleVector, svec, CodeInfo
import Base: uncompressed_ast

export addmethod!, codetransform!

"""
    jl_method_def(argdata, ci, mod) - C function wrapper

This is a wrapper of the C function with the same name, found in the Julia
source tree at julia/src/method.c

Use `addmethod!` or `codetransform!` instead of calling this function directly.
"""
jl_method_def(argdata::SimpleVector, ci::CodeInfo, mod::Module) =
    ccall(:jl_method_def, Cvoid, (SimpleVector, Any, Ptr{Module}), argdata, ci, pointer_from_objref(mod))
# `argdata` is `svec(svec(types...), svec(typevars...))`

"Recursively get the typevars from a `UnionAll` type"
typevars(T::UnionAll) = (T.var, typevars(T.body)...)
typevars(T::DataType) = ()

"Recursively get the body (sans typevars) from a `UnionAll` type"
body(T::UnionAll) = body(T.body)
body(T::DataType) = T

@nospecialize # the below functions need not specialize on arguments

"Get the module of a function"
getmodule(F::Type{<:Function}) = F.name.mt.module
getmodule(f::Function) = getmodule(typeof(f))

"Create a call singature"
makesig(f::Function, args) = Tuple{typeof(f), args...}

"""
    argdata(sig[, f])

Turn a call signature into the 'argdata' `svec` that `jl_method_def` uses
When a function is given in the second argument, it replaces the one in the
call signature.
"""
argdata(sig) = svec(body(sig).parameters::SimpleVector, svec(typevars(sig)...))
argdata(sig, f::Function) = svec(svec(typeof(f), body(sig).parameters[2:end]...), svec(typevars(sig)...))

"""
    addmethod(sig, ci)

Add a method to a function

Example:
```
g(x) = x + 13
ci = Base.uncompressed_ast(methods(g).ms[1])
function f end
addmethod!(Tuple{typeof(f), Any}, ci)
f(1) # returns 14
```
"""
function addmethod!(sig::Type{<:Tuple{F, Vararg}}, ci::CodeInfo) where {F<:Function}
    jl_method_def(argdata(sig), ci, getmodule(F))
end
addmethod!(f::Function, argtypes::Tuple, ci::CodeInfo) = addmethod(makesig(f, argtypes), ci)

@specialize # restore default

"""
    codetransform(tr!, src => dst)

Apply a code transformation function `tr!` on the methods of a function `src`,
adding the transformed methods to another function `dst`.

Example: Replace the constant 13 by 7 in a function.
```
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
"""
function codetransform!(tr!::Function, @nospecialize(p::Pair{<:Function, <:Function}))
    mod = getmodule(p.second)
    for m in methods(p.first).ms
        ci = uncompressed_ast(m)
        tr!(ci)
        @show argdata(m.sig, p.second), ci, mod
        jl_method_def(argdata(m.sig, p.second), ci, mod)
    end
end

end # module
