module NutrientVectorTypes
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
export Component

mutable struct NutrientVector
    name::String
    component::Array{Component, 1}
    NutrientVector() = begin
            #= none:1 =#
            new()
        end
end
export NutrientVector

StructTypes.StructType(::Type{Component}) = begin
        #= none:1 =#
        StructTypes.Mutable()
    end
StructTypes.StructType(::Type{NutrientVector}) = begin
        #= none:1 =#
        StructTypes.Mutable()
    end
end

