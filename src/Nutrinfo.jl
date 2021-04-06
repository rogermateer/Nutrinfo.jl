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

function add(key::String,ingredient1::Dict{String,Any},ingredient2::Dict{String,Any})::Any
    if (key ∉ keys(ingredient1) && key ∉ keys(ingredient2))
        return 0;
    end
    if (key ∉ keys(ingredient1))
        return ingredient2[key]
    end
    if (key ∉ keys(ingredient2))
        return ingredient1[key]
    end
    return ingredient1[key] + ingredient2[key];
end

function mix(ingredient1::Dict{String,Any},ingredient2::Dict{String,Any})::Dict{String,Any}
    allkeys = setdiff(union(keys(ingredient1),keys(ingredient2)),["Serving"]);
    return Dict( key=>add(key,ingredient1,ingredient2) for (key) in allkeys );
end

function combine(log::Array{Dict{String,Any},1})::Dict{String,Any}
    return reduce(mix,log);
end
export combine

# remove from Dict{String,Any} any entry whose key contains a '#'
function stripCommentsFromDict(dict::Dict{String,Any})::Dict{String,Any}
    return filter(p->!contains(first(p),"#"),dict);
end

# remove from Array{Dict{String,Any},1} any entry any of whose keys contains a '#'
function stripCommentsFromArrayOfDict(array::Array{Dict{String,Any},1})::Array{Dict{String,Any},1}
    return filter(x->!contains(join(collect(keys(x))),"#"),array);
end
export stripCommentsFromArrayOfDict

const Ingredient = Dict{String,String}                              ; export Ingredient
const CommentedLog = Dict{String,Union{String,Array{Ingredient,1}}}
const Log = Dict{String,Array{Ingredient,1}}                        ; export Log
const CommentedNutrients = Dict{String,Union{String,Ingredient}}
const Nutrients = Dict{String,Ingredient}                           ; export Nutrients

# Remove comments from the supplied log. This entails removing
# key-value pairs both where keys contain a "#" and where
# Array{Dict{String,Any},1} values (log entries) have any key
# containing a "#"
function stripCommentsFromLog(log#=::CommentedLog=#)::Log
    strippedLog = stripCommentsFromDict(log);
    return Dict( key=>stripCommentsFromArrayOfDict(Array{Dict{String,Any},1}(value)) for (key,value) in strippedLog );
end
export stripCommentsFromLog

# Remove comments from the supplied nutrients database. This entails
# removing both top and second level key-value pairs with keys that
# contain a "#"
function stripCommentsFromNutrients(nutrients#=::CommentedNutrients=#)::Nutrients
    strippedNutrients = stripCommentsFromDict(nutrients);
    return Dict( key=>stripCommentsFromDict(value) for (key,value) in strippedNutrients );
end
export stripCommentsFromNutrients

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

function parseUnits(ingredient::Ingredient)::Dict{String,Any}
    return Dict( key=>parseUnit(value) for (key,value) in ingredient);
end
export parseUnits

function parseIngredient(ingredient::Ingredient,nutrientsDatabase::Nutrients)::Dict{String,Any}
    return qty(parseUnit(ingredient["qty"]),parseUnits(nutrientsDatabase[ingredient["of"]]));
end
export parseIngredient

function parseIngredients(ingredients::Array{Ingredient,1},nutrientsDatabase::Nutrients)::Dict{String,Any}
    return combine(map(x->parseIngredient(x,nutrientsDatabase),ingredients));
end
export parseIngredients

end # module

