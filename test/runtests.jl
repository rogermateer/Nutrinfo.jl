using Test

using Nutrinfo

@testset "Unitful Intervals - the bread and butter of nutritional information calculations" begin
    @test Interval(0,1)u"μg" + 1u"μg" == Interval(1,2)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1,1.001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) != Interval(1000,1001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) == Interval(1000,1001)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1000,1001)u"μg"
    @test             uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")  != Interval(1000,1001)u"μg"
end

@testset "Custom Units" begin
    @test uconvert(u"kJ",1u"kcal") == 4.184u"kJ"
end

@testset "" begin
    # Source: myfitnesspal Fuerte Avocado - Medium (Generic)
    # Faffing with exact types...
    # FuerteAvocado = Dict{String,Quantity{Interval{Float64},Unitful.𝐌,Unitful.FreeUnits{(Unitful.g,),Unitful.𝐌,nothing}}}
    # FuerteAvocado = Dict{String,Quantity{Interval{Float64},Unitful.𝐌,Unitful.FreeUnits{Any,Any,Any}}}(
    FuerteAvocado = SortedDict{String,Any}(
        "Serving" => 150u"g",
        "Energy" => 240u"kcal",
        "Protein" => 3u"g",
        "Carbohydrates" => 13u"g",
        "Fat" => 22u"g"
    )
    FuerteAvocadoServing = SortedDict{String,Any}(
        "Serving" => 100u"g",
        "Energy" => 160u"kcal",
        "Protein" => 2u"g",
        "Carbohydrates" => (26/3)u"g",
        "Fat" => (44/3)u"g"
    )
    @test qty(100u"g",FuerteAvocado)==FuerteAvocadoServing
end
