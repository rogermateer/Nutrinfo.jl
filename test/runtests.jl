using Nutrinfo
using Test
using TestSetExtensions

@testset ExtendedTestSet "Unitful Intervals - the bread and butter of nutritional information calculations" begin
    @test Interval(0,1)u"μg" + 1u"μg" == Interval(1,2)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1,1.001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) != Interval(1000,1001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) == Interval(1000,1001)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1000,1001)u"μg"
    @test             uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")  != Interval(1000,1001)u"μg"
end

@testset ExtendedTestSet "Unitful Interval parsing - I'm open to correction, but apparently this doesn't 'just work' out of the box" begin
    @test parseUnit("1μg") == 1u"μg"
    @test parseUnit("1 μg") == 1u"μg"
    @test parseUnit("[0,1]μg") == Interval(0,1)u"μg"
    @test parseUnit(" [ 0 , 1 ] μ g ") == Interval(0,1)u"μg"
end

@testset ExtendedTestSet "Custom Units" begin
    @test uconvert(u"kJ",1u"kcal") == 4.184u"kJ"
end

@testset ExtendedTestSet "scale" begin
    nvA = JSON3.read("""{
        "name":"A",
        "component":[
            { "qty":"10g", "of":"one" },
            { "qty":"15g", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    nv2A = JSON3.read("""{
        "name":"2(A)",
        "component":[
            { "qty":"20g", "of":"one" },
            { "qty":"30g", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test string(nv2A) == string(scale(2,nvA))

    nvB = JSON3.read("""{
        "name":"B",
        "component":[
            { "qty":"10g", "custom":"1unit", "of":"one" },
            { "qty":"15g", "custom":"3unit", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    nv2B = JSON3.read("""{
        "name":"2.0(B)",
        "component":[
            { "qty":"20.0g", "custom":"2.0unit", "of":"one" },
            { "qty":"30.0g", "custom":"6.0unit", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test string(nv2B) == string(scale(2.0,nvB))
end
