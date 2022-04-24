module Nutrinfo
using Reexport
@reexport using IntervalArithmetic
@reexport using Unitful
@reexport using JSON3
@reexport using Graphs
@reexport using MetaGraphs
# @reexport using JSON
# @reexport using DataStructures

function parseUnit(x)
    x=replace(x," " => "") # be liberal in what you accept
    try
        return eval(quote @u_str($x) end)
    catch
        m=match(r"([[][^]]+[]])(.+)",x)
        i = m[1]
        u = m[2]
        return (@interval i)eval(quote @u_str($u) end)
    end
end
export parseUnit

function stringifyUnit(x)
    return replace(string(x), " " => "") # be conservative in what you do
end
export stringifyUnit

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
@unit serving "serving" serving 1 false
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
    component::Vector{Component}
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

# "scale" NutrientVector operation

function scale(ratio::R,component::Component)::Component where {R<:Real}
    scaledComponent = deepcopy(component)
    if (isdefined(component,:qty))
        scaledComponent.qty = stringifyUnit(ratio * parseUnit(component.qty))
    end
    if (isdefined(component,:custom))
        scaledComponent.custom = stringifyUnit(ratio * parseUnit(component.custom))
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

# "add" Component operation
function add(cA::Component,cB::Component)::Component # should it always return a Component? or would a NutrientVector sometimes be more appropriate?
    if (isdefined(cA,:of) && isdefined(cB,:of) && cA.of==cB.of)
        cAplusB = deepcopy(cA);
        if (isdefined(cA,:qty) && isdefined(cB,:qty))
            cAplusB.qty = stringifyUnit(parseUnit(cA.qty) + parseUnit(cB.qty));
        end
        return cAplusB;
    end
end

# "add" NutrientVector operation

function componentNames(nv::NutrientVector)::Vector{String}
    names = String[];
    for component in nv.component
        if (isdefined(component,:of))
            push!(names,component.of)
        end
    end
    return names;
end
export componentNames

function componentsNamed(nv::NutrientVector,name::String)::Vector{Component}
    components = Component[]
    for component in nv.component
        if (isdefined(component,:of))
            if (component.of==name) push!(components,component) end
        end
    end
    return components;
end
export componentsNamed

function add(nvA::NutrientVector,nvB::NutrientVector)::NutrientVector
    nvSum = NutrientVector()
    nvSum.name = "($(nvA.name))+($(nvB.name))"
    nvSum.component = Component[]
    namesA = componentNames(nvA)
    namesB = componentNames(nvB)
    # FIXME: deal gracefully with the cases where the number of
    # Components returned by componentsNamed() is less than or greater
    # than 1
    for name in intersect(namesA,namesB)
        push!(nvSum.component,add(componentsNamed(nvA,name)[1],componentsNamed(nvB,name)[1]))
    end
    for name in setdiff(namesA,namesB)
        push!(nvSum.component,componentsNamed(nvA,name)[1])
    end
    for name in setdiff(namesB,namesA)
        push!(nvSum.component,componentsNamed(nvB,name)[1])
    end
    push!(nvSum.component,JSON3.read("""{ "#" : "end" }""",Component)) # terminator convention
    return nvSum
end
export add

# NutrientVector MetaDiGraph functions

#=

Because of the generality of a NutrientVector having components which
are other NutrientVectors, we need the ability to detect inadvertent
cycles in the directed graph of NutrientVectors, and alert the user
that they are abusing the generality of the system and the
NutrientVector they've supplied can't be resolved against the database
of other NutrientVectors they've supplied.  Luckily the Julia
ecosystem provides some libraries (Graph.jl and MetaGraph.jl) which
simplify this exercise.  The following functions are my uses of these
libraries.

=#

"""

`Nutrinfo.resolve` helper function.

Creates a `MetaDiGraph` where vertices represent `NutrientVectors`,
and directed edges represent the `Component` relationships between
them.

"""
function make_graph()
    g = MetaDiGraph()
    set_indexing_prop!(g,:nv)
    return g
end
export make_graph

"""

`Nutrinfo.resolve` helper function.

Adds a vertex to our MetaDiGraph representing NutrientVector `nv`.

"""
function add_vertex(g::MetaDiGraph,nv::String)
    if length(collect(filter_vertices(g,:nv,nv)))==0
        println("Adding vertex $nv")
        add_vertex!(g,:nv,nv)
    else
        println("Vertex $nv already exists")
    end
end
export add_vertex

"""

`Nutrinfo.resolve` helper function.

Adds an edge to our MetaDiGraph representing the relationship that
NutrientVector `src` has quantity `qty` of NutrientVector `dst` as a
Component.

"""
function add_edge(g::MetaDiGraph,src::String,dst::String,qty::String)
#    println("Adding edge $src -> $dst with quantity $qty")
#    try
        add_edge!(g,g[src,:nv],g[dst,:nv],:qty,qty)
#    catch
#        println("Edge $src -> $dst (with quantity $qty?) already exists")
#    end
end
export add_edge

"""

`Nutrinfo.resolve` helper function.

Lists all the cycles in our MetaDiGraph.  We require that there be no
cycles if we are going to be able to use `list_paths()`.  So this
function should be called before calling `list_paths()` to ensure that
the latter terminates.

"""
function list_cycles(g::MetaDiGraph)
    cycle_list = []
    for cycle in simplecycles(g)
        push!(cycle_list,map(v->props(g,v)[:nv],cycle))
    end
    return cycle_list
end
export list_cycles

"""

`Nutrinfo.resolve` helper function.

Lists all edges in our MetaDiGraph as three element arrays of the form
`[src,qty,dst]`, representing the relationship that NutrientVector
`src` has quantity `qty` of NutrientVector `dst` as a Component.

"""
function list_edges(g::MetaDiGraph)
    edge_list = []
    for e in edges(g)
        push!(edge_list,[ props(g,e.src)[:nv], props(g,e)[:qty], props(g,e.dst)[:nv] ])
    end
    return edge_list
end
export list_edges

"""

`Nutrinfo.resolve` helper function.

Lists all vertices in our MetaDiGraph with outdegree zero.  These
correspond to NutrientVectors that either are terminal basis
NutrientVectors, or are NutrientVectors that we haven't yet tried to
expand.

"""
function list_frontier(g::MetaDiGraph)::Vector{String}
    frontier_list = [];
    println("Graph contains vertices $(collect(vertices(g)))")
    for v in vertices(g)
        if outdegree(g,v)==0
            println("Properties of vertex $v are $(props(g,v))")
            push!(frontier_list,props(g,v)[:nv]);
        end
    end
    return frontier_list
end
export list_frontier

i=0;
function _list_paths(prefix::Vector{String},g::MetaDiGraph,src::String)::Vector{Vector{String}}
    # println("_list_paths($(prefix),g,$(src))")
    global i += 1
    # println(i)
    outnbrs = outneighbors(g,g[src,:nv])
    if (length(outnbrs) > 0)
        path_list = Vector{Vector{String}}()
        for d in outnbrs
            s = g[src,:nv]
            dst = props(g,d)[:nv]
            for path in _list_paths(String[prefix...,props(g,s,d)[:qty],dst], g, dst)
                push!(path_list,path)
            end
        end
        # println("path_list=$(path_list)")
        return path_list
    else
        # println("prefix=$(prefix)")
        return [prefix]
    end
end

"""

`Nutrinfo.resolve` helper function.

List all possible paths in the supplied MetaDiGraph `g` that start at
vertex `src`.

Each path is an odd-length array of strictly alternating names of
vertices and edges, beginning with the vertex `src`.

This can be expected not to terminate if `g` contains any cycles, so use
`list_cycles()` to determine that first.

"""
function list_paths(g::MetaDiGraph,src::String)::Vector{Vector{String}}
    return _list_paths(String[src],g,src)
end
export list_paths

"""

`Nutrinfo.resolve` helper function.

Adds all the Components of the supplied NutrientVector `src` as edges
from the existing vertex for `src` to either new or existing vertices
for the Components of `src`.

"""
function _add_components(g::MetaDiGraph,src::NutrientVector)
    println("Adding components for $src")
    for dst in src.component
        if (isdefined(dst,:of) && isdefined(dst,:qty))
            add_vertex(g,dst.of)
            add_edge(g,src.name,dst.of,dst.qty)
        end
    end
end

struct ResolveException <: Exception
    message::String
end
export ResolveException

"""

`Nutrinfo.resolve` helper function.

Try to find the NutrientVector with name `name` in the supplied
NutrientVector database `nvDB`, and return the collection of matching
NutrientVectors.

If this collection is empty, there is no match, and the algorithm
regards the NutrientVector in question as a basis vector.  (It could
also mean that the database is missing an entry that should be there,
and it is up to the user to decide whether that is the case, and to
add it if possible.)

If the collection has exactly one member, that is a match.

If it has more than one member, then it is flagged as an error by the
algorithm, and the database needs to be fixed to resolve the
duplication.

"""
function _find_nv_in_db(name::String,nvDB::Vector{NutrientVector})::Vector{NutrientVector}
    return filter(nv -> nv.name==name, nvDB)
end

"""

`Nutrinfo.resolve` helper function.

Take a `path` (produced by `list_paths()`) and "reduce" it to the
equivalent "weight" of Component denoted by its terminal vertex.

Multiply all the edges together, and then divide by all the servings
of internal vertices

edges are path[2], path[4], ..., path[length(path)-1]

internal vertices are path[3], path[5], ..., path[length(path)-2]

The point of this exercise is to create Components for all paths
returned by `list_paths()` so that they can be added together to get
the Components of the output of `resolve()`.

"""
function reduce_path(path::Vector{String},nvDB::Vector{NutrientVector})::Component
    pathComponent = Component()
    pathComponent.of = path[length(path)]
    qty = parseUnit("1")
    for j in 2:2:length(path)-2
        edgeWeight = path[j]
        vertex = path[j+1]
        vertexMatches = _find_nv_in_db(vertex,nvDB)
        if (length(vertexMatches) == 0)
            throw(ResolveException("path $path is invalid for supplied NutrientVector DB. internal vertex '$vertex' has no definition"))
        end
        if (length(vertexMatches) > 1)
            throw(ResolveException("path $path is invalid for supplied NutrientVector DB. internal vertex '$vertex' has more than one definition"))
        end
        # println("HELLO")
        # println("vertexMatches == $vertexMatches")
        # println("HELLO")
        vertexServingComponents = filter(x->(isdefined(x,:of) && x.of=="serving"),vertexMatches[1].component)
        # println("HELLO")
        # println("vertexServingComponents == $vertexServingComponents")
        # println("HELLO")
        if (length(vertexServingComponents) == 0)
            throw(ResolveException("$(vertexMatches[1]) has no 'serving' component"))
        end
        if (length(vertexServingComponents) > 1)
            throw(ResolveException("$(vertexMatches[1]) has more than one 'serving' component"))
        end
        vertexServing = vertexServingComponents[1].qty
        # println("HELLO")
        # println("qty == $qty * $edgeWeight / $vertexServing")
        # println("HELLO")
        qty = qty * parseUnit(edgeWeight) / parseUnit(vertexServing)
    end
    finalQty = parseUnit(path[length(path)-1])
    pathComponent.qty = stringifyUnit(qty * finalQty)
    return pathComponent
end
export reduce_path

"""

The "resolve" NutrientVector operation

"""
function resolve(nv::NutrientVector,nvDB::Vector{NutrientVector})::NutrientVector
    println("Resolve \"$(nv.name)\" given $(map(nv->nv.name,nvDB))")
    g = make_graph()

    frontier = list_frontier(g)

    add_vertex(g,nv.name)
    _add_components(g,nv)

    new_frontier = list_frontier(g)

    while Set(frontier) != Set(new_frontier)
        println("Frontier : $frontier -> $new_frontier")
        for src in new_frontier
            matches = _find_nv_in_db(src,nvDB)
            if length(matches)>1
                throw(ResolveException("multiple NutrientVectors are named '$name' : $matches"))
            end
            if length(matches)==1
                _add_components(g,matches[1])
            end
        end
        frontier = new_frontier
        new_frontier = list_frontier(g)
    end

    cycles = list_cycles(g)
    if length(cycles) > 0
        throw(ResolveException(replace("encountered cycles $cycles",r"\"" => "'",", " => ",")))
    end

    # at this point, g represents a fully expanded NutrientVector that
    # doesn't have any cycles. and the final value of frontier
    # represents the set of Components of this fully expanded
    # NutrientVector.

    # we can list all its paths and work out the contribution each of
    # them makes to the scaling of the basis NutrientVector that is at
    # the end of each path.

    componentDict = Dict{String,Component}()
    for path in list_paths(g,nv.name)
        println("Path $path")
        basis = path[end]
        if (!haskey(componentDict,basis))
            componentDict[basis] = JSON3.read("""{"qty":"0g","of":"$basis"}""",Component)
        end
        componentDict[basis] = add(componentDict[basis],reduce_path(path,nvDB))
    end

    # sort the dictionary by its component names
    componentDict = sort(collect(componentDict),by = x->x[1])

    println("componentDict = $componentDict")

    nvResolve = NutrientVector()
    nvResolve.name = "resolved($(nv.name))"
    nvResolve.component = Component[]

    for (name,component) in componentDict
        if (name=="SERVING")
            continue  # ignore the special case of the serving component
        end
        println("$name=$component")
        # round qty values of each component to 5 digits

        push!(nvResolve.component,component)
    end

    push!(nvResolve.component,JSON3.read("""{"#":"end"}""",Component))

    return nvResolve
end
export resolve


function stringifyNV(nv::NutrientVector)::String
    components = join(map(JSON3.write,nv.component),",\n        ");
    return replace("""{
    "name":"$(nv.name)",
    "component":[
        $(components)
    ]
}""",r"\"" => "'");
end
export stringifyNV

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

function combine(log::Vector{Dict{String,Any}})::Dict{String,Any}
    return reduce(mix,log);
end
export combine

# remove from Dict{String,Any} any entry whose key contains a '#'
function stripCommentsFromDict(dict::Dict{String,Any})::Dict{String,Any}
    return filter(p->!contains(first(p),"#"),dict);
end

# remove from Vector{Dict{String,Any}} any entry any of whose keys contains a '#'
function stripCommentsFromArrayOfDict(array::Vector{Dict{String,Any}})::Vector{Dict{String,Any}}
    return filter(x->!contains(join(collect(keys(x))),"#"),array);
end
export stripCommentsFromArrayOfDict

const Ingredient = Dict{String,String}                              ; export Ingredient
const CommentedLog = Dict{String,Union{String,Vector{Ingredient}}}
const Log = Dict{String,Vector{Ingredient}}                        ; export Log
const CommentedNutrients = Dict{String,Union{String,Ingredient}}
const Nutrients = Dict{String,Ingredient}                           ; export Nutrients

# Remove comments from the supplied log. This entails removing
# key-value pairs both where keys contain a "#" and where
# Vector{Dict{String,Any}} values (log entries) have any key
# containing a "#"
function stripCommentsFromLog(log#=::CommentedLog=#)::Log
    strippedLog = stripCommentsFromDict(log);
    return Dict( key=>stripCommentsFromArrayOfDict(Vector{Dict{String,Any}}(value)) for (key,value) in strippedLog );
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

function parseIngredients(ingredients::Vector{Ingredient},nutrientsDatabase::Nutrients)::Dict{String,Any}
    return combine(map(x->parseIngredient(x,nutrientsDatabase),ingredients));
end
export parseIngredients

function digest(nutrientsFile::String,nutrientsList::Vector{String},logFile::String,logEntry::String)::String
    commentedLog = JSON.parsefile(logFile)::CommentedLog;
    return "Hello";
    log = stripCommentsFromLog(commentedLog);
    commentedNutrients = JSON.parsefile(nutrientsFile);
    nutrients = Nutrients(stripCommentsFromNutrients(commentedNutrients));
    intake = parseIngredients(Vector{Ingredient}(log[logEntry],nutrients));
    retval = "\n" * logEntry;
    for nutrient in nutrientsList
        retval *= ":" * nutrient * "=" * intake[nutrient];
    end
    return retval;

    logEntry = Vector{Ingredient}(log[logEntry]);
    print(json(logEntry,4));
    print(nutrients["water"]);

    # using Debugger;@enter parseIngredients(log20210401,nutrients)

    print(json(parseIngredients(logEntry,nutrients),4));
end
export digest

end # module

