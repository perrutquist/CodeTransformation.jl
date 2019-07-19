module CodeTransformation

import Core: SimpleVector, svec, CodeInfo
import Base: uncompressed_ast, unwrap_unionall

export addmethod!, codetransform!

# Most of this code is derived from Nathan Daly's DeepcopyModules.jl
# which is under the MIT license.
# https://github.com/NHDaly/DeepcopyModules.jl

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
argdata(sig) = svec(unwrap_unionall(sig).parameters::SimpleVector, svec(typevars(sig)...))
argdata(sig, f::Function) = svec(svec(typeof(f), unwrap_unionall(sig).parameters[2:end]...), svec(typevars(sig)...))

"""
    addmethod!(f, argtypes, ci)

Add a method to a function.

The types of the arguments is given as a `Tuple`.

Example:
```
g(x) = x + 13
ci = code_lowered(g)[1]
function f end
addmethod!(f, (Any,), ci)
f(1) # returns 14
```
"""
addmethod!(f::Function, argtypes::Tuple, ci::CodeInfo) = addmethod!(makesig(f, argtypes), ci)
"""
    addmethod(sig, ci)

Alternative syntax where the call signature is a `Tuple` type.

Example:
```
addmethod!(Tuple{typeof(f), Any}, ci)
```
"""
function addmethod!(sig::Type{<:Tuple{F, Vararg}}, ci::CodeInfo) where {F<:Function}
    jl_method_def(argdata(sig), ci, getmodule(F))
end

@specialize # restore default

"""
    codetransform!(tr, dst, src)

Apply a code transformation function `tr` on the methods of a function `src`,
adding the transformed methods to another function `dst`.

Example: Search-and-replace a constant in a function.
```
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
```
"""
function codetransform!(tr::Function, @nospecialize(dst::Function), @nospecialize(src::Function))
    mod = getmodule(dst)
    for m in methods(src).ms
        ci = uncompressed_ast(m)
        ci = tr(ci)
        jl_method_def(argdata(m.sig, dst), ci, mod)
    end
end
"Alternative syntax: codetransform!(tr, src => dst)"
codetransform!(tr::Function, @nospecialize(p::Pair{<:Function, <:Function})) =
    codetransform!(tr, p.second, p.first)

end # module
