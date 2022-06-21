## load file and parse as json, declare fortran to julia specifics
using JSON
dir = dirname(ARGS[1])
f = basename(ARGS[1])
json = read(joinpath(dir, f), String) |> JSON.parse |> x -> x["Program"]
# fortran specifics
intrinsics = ["SIN", "COS", "TAN", "ASIN", "ACOS", "ATAN", "SQRT", "EXP", "ABS"]
syntax = Dict("**" => "^", ".TRUE." => "true", ".FALSE." => "false")

## get variables, parameters and specified declarations
getVariablesInBlock(json, blockname, name) = filter(json) do x
    haskey(x, blockname) && x[blockname]["Name"] == name
end |> x -> isempty(x) ? x : x[1]["CommonStatement"]["Items"] .|> lowercase .|> Symbol
parameters = getVariablesInBlock(json["Main"], "CommonStatement", "CONSTNTS")
variables = getVariablesInBlock(json["Main"], "CommonStatement", "VARIBLES")
derivatives = map(x -> Symbol(x, :p), variables)
specifieds = getVariablesInBlock(json["Main"], "CommonStatement", "SPECFIED")
algebraics = getVariablesInBlock(json["Main"], "CommonStatement", "ALGBRAIC")

## get assignments statements from main, eqns and io and convert to julia expressions
toJulia(x::Vector{Any}) = x[1] in intrinsics ? join(toJulia.(x), "(") * ")" : toJulia(x[1]) * "[" * join(toJulia.(x[2:end]), ',') * "]"
toJulia(x::Dict) = collect(values(x))[1] |> join |> lowercase
toJulia(x) = x in keys(syntax) ? syntax[x] : string(x) |> lowercase
toExpr(x) = [toJulia(as["lhs"]) * "=" * join(toJulia.(as["rhs"])) for as in x] .|> Meta.parse

main_as = toExpr(filter(x -> haskey(x, "AssignmentStatement"), json["Main"]) .|> x -> x["AssignmentStatement"])
eqns_as = toExpr(filter(x -> haskey(x, "AssignmentStatement"), json["EQNS1"]) .|> x -> x["AssignmentStatement"])
io_as = toExpr(filter(x -> haskey(x, "AssignmentStatement"), json["IO"]) .|> x -> x["AssignmentStatement"])
as_all = [main_as; eqns_as; io_as]

## z assignments
assignZ(ex::Expr) = ex.args[1] isa Expr && ex.args[1].args[1] == :z
isZ(ex::Expr) = ex.head == :ref && ex.args[1] == :z
isZ(ex) = false
z_as = [ex for ex in as_all if assignZ(ex)]

# unwind
# unwindZ(x::AbstractArray, d::Dict) = Expr(:call, map(x -> unwindZ(x, d), x)...)
# unwindZ(x::Expr, d::Dict) = isZ(x) ? unwindZ(d[x], d) : unwindZ(x.args, d)
# unwindZ(x, d::Dict) = x
# z_dict = Dict(as.args[1] => as.args[2] for as in z_as)
# znot_dict = Dict(key => unwindZ(value, z_dict) for (key, value) in z_dict)
z_dict = Dict()

## remove z assignments from io
# replaceZ(x::Expr, d::Dict) = isZ(x) ? d[x] : replaceZ(x.args, d)
# replaceZ(x::AbstractArray, d::Dict) = Expr(:call, map(x -> replaceZ(x, d), x)...)
# replaceZ(x, d::Dict) = x
# io_znot_as = [Expr(:(=), as.args[1], replaceZ(as.args[2], znot_dict)) for as in io_as]

# ## non z assignments
# const_as = [ex for ex in main_as if ex isa Expr && (ex.args[1] in algebraics || assignZ(ex))]

## output
# which variables, specifieds, parameters needed
# find endpoints (leaves) of expression tree, leaves z indexes as is
leaves(ex::Expr) = length(ex.args) == 2 && ex.args[1] == :z ? ex : vcat(leaves(ex.args)...)
leaves(v::AbstractArray) = leaves.(v)
leaves(x) = x
uses(ex::Expr, l::AbstractArray) = filter(x -> x in l, leaves(ex) |> unique!)
uses(v::AbstractArray, l::AbstractArray) = vcat(map(x -> uses(x, l), v)...) |> unique

# return z variables used in an expression
Zs(ex::Expr) = [x for x in leaves(ex) if typeof(x) == Expr && x.args[1] == :z]

## simplify expressions
# simp(x::Expr) = x.head == :call && x.args[1] in [:sin, :cos] ? Symbol(string(x.args[1])[1], x.args[2]) : simp(x.args)
# simp(x::AbstractArray) = Expr(:call, simp.(x)...)
# simp(x) = x
# io_znot_simp_as = [Expr(:(=), x.args[1], simp(x.args[2])) for x in io_znot_as]

## non z assignments
const_as = [ex for ex in main_as if ex isa Expr && (ex.args[1] in algebraics || assignZ(ex))]

## write outputs
N = length(variables) ÷ 2
zN = filter(getVariablesInBlock(json["Main"], "CommonStatement", "MISCLLNS")) do x
    occursin("z", string(x))
end |> x -> isempty(x) ? x : x[1] |> string |> x -> parse(Int64, x[3:end-1]) # size of z array
constants = [parameters; map(x -> x.args[1], filter(!assignZ, const_as))] # includes non-parameter constants, e.g. MT in sprinting model
include(joinpath(dir, "eom_str.jl"))
include(joinpath(dir, "fcns_str.jl"))
include(joinpath(dir, "params_str.jl"))
files = Dict("eom.jl" => eom_str, "functions.jl" => fcns_str, "parameters.jl" => params_str)

for (key, value) in files
    open(joinpath(dir, key), "w") do io
        write(io, value)
    end
end
