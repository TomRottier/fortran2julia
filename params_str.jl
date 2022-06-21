# constants = [parameters; map(x -> x.args[1], filter(!assignZ, const_as))] # includes non-parameter constants, e.g. MT in sprinting model

if zN == 0
    params_str =
"# Automatically generated
struct Params{T}
    $( join(constants, "::T\n\t") )::T

end

# intialise with constants values
function Params($( join(parameters, ", ") ))
    $( join(filter(!assignZ, const_as), "\n\t") )

    return Params($( join(constants, ", ") ))
end
 "
elseif zN != 0 
    params_str =
"# Automatically generated
struct Params{T}
    z::Vector{Float64}
    $( join(constants, "::T\n\t") )::T

end

# initialise with constant values
function Params($( join(parameters, ", ") ))
    z = Vector{Float64}(undef, $zN)
    $( join(filter(!assignZ, const_as), "\n\t") )
    $( join(filter(assignZ, const_as), "\n\t") )

    return Params(z, $( join(constants, ", ") ))
end
"
else
    error("param_str not matching")
end