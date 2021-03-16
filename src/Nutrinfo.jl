module Nutrinfo
using Reexport
@reexport using IntervalArithmetic
@reexport using Unitful
@reexport using JSON
# @reexport using DataStructures

function scale(ratio::Real,ingredient::Dict{String,Any})::Dict{String,Any}
    return Dict( key=>value*ratio for (key,value) in ingredient);
end
export scale
#=

Takes an ingredient (which is a Dictionary mapping nutrients/energy to
quantities) and a servingSize, and creates a new Dictionary mapping
nutrients/energy to quantities which represents the ingredient scaled
by the supplied serving size relative to the servingSize mapping entry
it contains.

=#
function qty(serving::Any,ingredient::Dict{String,Any})::Dict{String,Any}
    return scale(serving/ingredient["Serving"],ingredient);
end
export qty;

function mix(ingredient1::Dict{String,Any},ingredient2::Dict{String,Any})::Dict{String,Any}
    allkeys = union(keys(ingredient1),keys(ingredient2));
    return Dict( key=>ingredient1[key]+ingredient2[key] for (key) in allkeys );
end

function combine(log::Array{Dict{String,Any},1})::Dict{String,Any}
    return reduce(mix,log);
end
export combine

# remove from the log any entry any of whose keys contains a '#'
function stripComments(log::Array{Dict{String,Any},1})::Array{Dict{String,Any},1}
    return filter(x->!contains(join(collect(keys(x))),"#"),log);
end
export stripComments

function Base.isapprox(l::Dict{String,Any}, r::Dict{String,Any})
    l === r && return true
    if length(l) != length(r) return false end
    for pair in l
        if !in(pair, r, isapprox)
            return false
        end
    end
    true
end

function parseUnit(x)
    return eval(quote @u_str($x) end)
end
export parseUnit

function parseUnits(ingredient::Dict{String,Any})::Dict{String,Any}
    return Dict( key=>parseUnit(value) for (key,value) in ingredient);
end
export parseUnits

function parseIngredient(ingredient::Dict{String,Any},nutrientsDatabase::Dict{String,Any})::Dict{String,Any}
    return qty(parseUnit(ingredient["qty"]),parseUnits(nutrientsDatabase[ingredient["of"]]));
end
export parseIngredient

function parseIngredients(log::Array{Dict{String,Any},1},nutrientsDatabase::Dict{String,Any})::Dict{String,Any}
    return combine(map(x->parseIngredient(x,nutrientsDatabase),log));
end
export parseIngredients

end # module

