coefs = Expr.(:(=), map(x -> Meta.parse(join(x.args[1].args)), filter(x -> x.args[1] isa Expr && x.args[1].args[1] == :coef, eqns_as)),  map(x -> x.args[2], filter(x -> x.args[1] isa Expr && x.args[1].args[1] == :coef, eqns_as)))
rhss = Expr.(:(=), map(x -> Meta.parse(join(x.args[1].args)), filter(x -> x.args[1] isa Expr && x.args[1].args[1] == :rhs, eqns_as)), map(x -> x.args[2], filter(x -> x.args[1] isa Expr && x.args[1].args[1] == :rhs, eqns_as)))

eom_str = 
"# Automatically generated
function eom(u,p,t)
    @unpack $(join(constants, ", "))$( isempty(z_as) ? "" : ", z") = p
    @inbounds $(join(variables, ", ")) = u

    # specified variables
    $( begin 
        str = string.(uses(filter(x -> x.args[1] isa Expr && x.args[1].args[1] in [:z, :coef, :rhs], eqns_as), specifieds)) .|>
        x -> "$x = _$x(t)"
        join(str, "; ")
    end)


    # calculated variables
    $(filter(eqns_as) do x
        x.head ≠ :incomplete &&
        x.args[1] ∉ [variables; derivatives; specifieds; keys(z_dict)] &&
        !(x.args[1] isa Expr)
    end |> x -> join(x, "\n\t")
    )

    # z variables
    $(filter(assignZ, eqns_as) |> x -> join(x, "\n\t"))

    # coef
    $( join(coefs, "\n\t") )
    
    # rhs
    $( join(rhss, "\n\t") )

    # set up system of equations
    coef = @SMatrix [$(["coef$i$j" for i in 1:N, j in 1:N] |> x -> [join(row, ' ') for row in eachrow(x)] |> x -> join(x, "; "))]
    rhs = @SVector [$(join(["rhs$i" for i in 1:N], ", "))]

    # derivatives
    $(filter(x -> x.args[1] in derivatives, eqns_as)[1:end ÷ 2] |> x -> join(x, "\n\t"))
    @inbounds $(derivatives[end ÷ 2 + 1:end] |> x -> join(x, ", ")) = coef \\ rhs

    return @SVector [$(join(derivatives, ", "))]
end
"  