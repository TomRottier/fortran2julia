function fcns_fn(x, constants, variables, specifieds)
    name = string(x.args[1])
    params = join(uses(x, constants), ", ")
    vars = join(variables, ", ")
    specs = join(uses(x, specifieds), ", ")
    specs_eqs = join(map(x -> "$x = $x(t)", split(specs, ", ")), "; ")
    equation = string(x.args[2])

"function $name(sol, t)
    $( isempty(params) ? "" : "@unpack $params = sol.prob.p" )
    $( isempty(specs) ? "" : "@unpack $specs = sol.prob.p" )
    @inbounds $vars = sol(t)

    $( isempty(specs) ? "" : specs_eqs )
    
    return $equation
end

$name(sol) = [$name(sol,t) for t in sol.t]
"
end

fcns_str = 
"# Automatically generated
$(join([fcns_fn(x, constants, variables, specifieds) for x in io_znot_as if !isZ(x.args[1])], "\n\n"))

te(sol, t) = ke(sol, t) + pe(sol, t)
te(sol) = [te(sol, t) for t in sol.t]
"
