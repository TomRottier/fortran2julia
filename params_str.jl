# constants = [parameters; map(x -> x.args[1], filter(!assignZ, const_as))] # includes non-parameter constants, e.g. MT in sprinting model

if zN == 0 && isempty(specifieds)
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
elseif zN == 0
    params_str =
"# Automatically generated
struct Params{T,$( join(["F$i" for i in 1:length(specifieds)], ", ") )}
    $( join(["$x::F$i" for (i, x) in enumerate(specifieds)], "\n\t") )
    $( join(constants, "::T\n\t") )::T

end

# intialise with constants values
function Params($( join([specifieds; parameters], ", ") ))
    $( join(filter(!assignZ, const_as), "\n\t") )

    return Params($( join([specifieds; constants], ", ") ))
end
"
elseif zN != 0 && isempty(specifieds)
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
elseif zN != 0
    params_str =
"# Automatically generated
struct Params{T,$( join(["F$i" for i in 1:length(specifieds)], ", ") )}
    z::Vector{Float64}
    $( join(["$x::F$i" for (i, x) in enumerate(specifieds)], "\n\t") )
    $( join(constants, "::T\n\t") )::T

end

# initialise with constant values
function Params($( join([specifieds; parameters], ", ") ))
    z = Vector{Float64}(undef, $zN)
    $( join(filter(!assignZ, const_as), "\n\t") )
    $( join(filter(assignZ, const_as), "\n\t") )

    return Params(z, $( join(specifieds, ", ") ), $( join(constants, ", ") ))
end
"
else
    error("param_str not matching")
end