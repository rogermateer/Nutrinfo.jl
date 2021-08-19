module Nutrinfo
using Reexport
@reexport using IntervalArithmetic
@reexport using Unitful
@reexport using JSON3
# @reexport using JSON
# @reexport using DataStructures

function parseUnit(x)
    x=replace(x," " => "") # be liberal in what you accept
    try 
        return eval(quote @u_str($x) end)
    catch
        m=match(r"([[][^]]+[]])(.+)",x);
        i = m[1]
        u = m[2]
        return (@interval i)eval(quote @u_str($u) end)
    end
end
export parseUnit

# These custom units should probably be listed in a separate
# user-specific JSON file to be defined as independent units here.
#
# The idea behind these is that for a given nutrient vector, the log
# data will contain some entries with only a qty key-value pair, some
# with only a custom key-value pair, and some with both.
#
# The sample of qty value/custom value ratios for a given custom unit
# for a given nutrient vector can then be used to calculate a
# confidence interval (or perhaps a mean and standard deviation) for
# what qty that custom unit corresponds to for that nutrient vector in
# cases where the qty is absent.
@unit BOTTLE "BOTTLE" BOTTLE 1 false
@unit bottle "bottle" bottle 1 false
@unit burger "burger" burger 1 false
@unit cup "cup" cup 1 false
@unit glass "glass" glass 1 false
@unit meatball "meatball" meatball 1 false
@unit piece "piece" piece 1 false
@unit scoop "scoop" scoop 1 false
@unit slice "slice" slice 1 false
@unit tablespoon "tablespoon" tablespoon 1 false
@unit teaspoon "teaspoon" teaspoon 1 false
@unit unit "unit" unit 1 false
function __init__()
    Unitful.register(Nutrinfo)
end

# BEGIN copy-pasted generated code without module wrapper

import StructTypes
mutable struct Component
    var"#"::Union{Nothing, String}
    qty::Union{Nothing, String}
    custom::Union{Nothing, String}
    of::Union{Nothing, String}
    Component() = begin
            #= none:1 =#
            new()
        end
end

mutable struct NutrientVector
    name::String
    component::Array{Component, 1}
    NutrientVector() = begin
            #= none:1 =#
            new()
        end
end

StructTypes.StructType(::Type{Component}) = begin
        #= none:1 =#
        StructTypes.Mutable()
    end
StructTypes.StructType(::Type{NutrientVector}) = begin
        #= none:1 =#
        StructTypes.Mutable()
    end

# END copy-pasted generated code without module wrapper

# we need to implement custom equality operators, because == doesn't
# behave the way we want, and StructEquality doesn't handle undefined
# fields appropriately

function Base.:(==)(s1::Component, s2::Component)

    if xor(isdefined(s1,:var"#"),isdefined(s2,:var"#")) return false end
    if isdefined(s1,:var"#") && isdefined(s2,:var"#") && ( s1.var"#" != s2.var"#" ) return false end
    # at this point, var"#" is equal because either both fields are undefined or both are defined and equal
    
    if xor(isdefined(s1,:qty),isdefined(s2,:qty)) return false end
    if isdefined(s1,:qty) && isdefined(s2,:qty) && ( s1.qty != s2.qty ) return false end
    # at this point, qty is equal because either both fields are undefined or both are defined and equal

    if xor(isdefined(s1,:custom),isdefined(s2,:custom)) return false end
    if isdefined(s1,:custom) && isdefined(s2,:custom) && ( s1.qty != s2.qty ) return false end
    # at this point, custom is equal because either both fields are undefined or both are defined and equal

    if xor(isdefined(s1,:of),isdefined(s2,:of)) return false end
    if isdefined(s1,:qty) && isdefined(s2,:qty) && ( s1.qty != s2.qty ) return false end
    # at this point, of is equal because either both fields are undefined or both are defined and equal

    return true
end

function Base.:(==)(s1::NutrientVector, s2::NutrientVector)
    if s1.name != s2.name return false end
    if length(s1.component) != length(s2.component) return false end
    for j in 1:length(s1.component)
        if s1.component[j] != s2.component[j] return false end
    end
    return true
end

export Component # added statement
export NutrientVector # added statement

function scale(ratio::R,component::Component)::Component where {R<:Real}
    scaledComponent = deepcopy(component)
    if (isdefined(component,:qty))
        scaledComponent.qty = replace(string(ratio * parseUnit(component.qty)), " " => "") # be conservative in what you do
    end
    if (isdefined(component,:custom))
        scaledComponent.custom = replace(string(ratio * parseUnit(component.custom)), " " => "") # be conservative in what you do
    end
    return scaledComponent
end

function scale(ratio::R,nutrientVector::NutrientVector)::NutrientVector where {R<:Real}
    scaledNutrientVector = deepcopy(nutrientVector)
    scaledNutrientVector.name = "$ratio($(nutrientVector.name))"
    for j in 1:length(nutrientVector.component)
        scaledNutrientVector.component[j] = scale(ratio,nutrientVector.component[j])
    end
    # or maybe just
    # scaledNutrientVector.component = map(x->scale(ratio,x), nutrientvector.component)
    return scaledNutrientVector
end


function scale(ratio::Real,ingredient::Dict{String,Any})::Dict{String,Any}
    return Dict( key=>value*ratio for (key,value) in ingredient);
end
export scale


###################################################################################################
##                                                                                               ##
#  OLD STUFF BELOW HERE. IT NEEDS TO BE INTEGRATED INTO THE NEW STUFF ABOVE, AND THEN ELIMINATED  #
##                                                                                               ##
###################################################################################################


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

function parseUnits(ingredient::Ingredient)::Dict{String,Any}
    return Dict( key=>parseUnit(value) for (key,value) in ingredient);
end
export parseUnits

function parseIngredient(ingredient::Ingredient,nutrientsDatabase::Nutrients)::Dict{String,Any}
    println(ingredient);
    println(parseUnit(ingredient["qty"]));
    println(nutrientsDatabase[ingredient["of"]]);
    println(parseUnits(nutrientsDatabase[ingredient["of"]]));
    return qty(parseUnit(ingredient["qty"]),parseUnits(nutrientsDatabase[ingredient["of"]]));
end
export parseIngredient

function parseIngredients(ingredients::Array{Ingredient,1},nutrientsDatabase::Nutrients)::Dict{String,Any}
    return combine(map(x->parseIngredient(x,nutrientsDatabase),ingredients));
end
export parseIngredients

function digest(nutrientsFile::String,nutrientsList::Array{String,1},logFile::String,logEntry::String)::String
    commentedLog = JSON.parsefile(logFile)::CommentedLog;
    return "Hello";
    log = stripCommentsFromLog(commentedLog);
    commentedNutrients = JSON.parsefile(nutrientsFile);
    nutrients = Nutrients(stripCommentsFromNutrients(commentedNutrients));
    intake = parseIngredients(Array{Ingredient,1}(log[logEntry],nutrients));
    retval = "\n" * logEntry;
    for nutrient in nutrientsList
        retval *= ":" * nutrient * "=" * intake[nutrient];
    end
    return retval;

    logEntry = Array{Ingredient,1}(log[logEntry]);
    print(json(logEntry,4));
    print(nutrients["water"]);

    # using Debugger;@enter parseIngredients(log20210401,nutrients)

    print(json(parseIngredients(logEntry,nutrients),4));
end
export digest

end # module

