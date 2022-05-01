using Nutrinfo
using Test
using TestSetExtensions

ALL = true

# the set of tests to run if ALL is false
TESTS = [
    # "unitfulIntervals",
    # "scale",
    # "add",
    # "graph",
    # "reduce_path",
    "resolve",
]

if ALL || "unitfulIntervals" ∈ TESTS

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

end

if ALL || "scale" ∈ TESTS

    #=

    NutrientVector 'scale' operation:

    Multiply a nutrient vector by a given scaling factor by
    multiplying the qty and/or custom entries of each of its
    components by that scaling factor.

    =#

    @testset ExtendedTestSet "'scale' NutrientVector operation" begin
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

end

if ALL || "add" ∈ TESTS

    #=

    NutrientVector 'add' operation:

    Add two nutrient vectors by collecting all of the components of
    both, adding the 'qty' and/or 'custom' entries of any components
    with matching 'of' entries.

    =#

    @testset ExtendedTestSet "'add' Component operation" begin
        cA1 = JSON3.read("""{ "qty":"100J", "of":"Energy" }""",Component);
        cA2 = JSON3.read("""{ "qty":"3g", "of":"Protein" }""",Component);
        cA3 = JSON3.read("""{ "qty":"4g", "of":"Fat" }""",Component);
        cA4 = JSON3.read("""{ "#":"end" }""",Component);

        cB1 = JSON3.read("""{ "qty":"80J", "of":"Energy" }""",Component);
        cB2 = JSON3.read("""{ "qty":"2g", "of":"Carbs" }""",Component);
        cB3 = JSON3.read("""{ "qty":"7g", "of":"Fat" }""",Component);
        cB4 = JSON3.read("""{ "#":"end" }""",Component);

        cA1plusB1 = JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component);
        @test string(cA1plusB1) == string(add(cA1,cB1));

        # FIXME: what should we do when two Components aren't addable
        # as a Component?

        # println(add(cA2,cB2))

        # it could be a sensible option to upgrade the sum to the
        # NutrientVector that is the sum of the two NutrientVectors
        # that have only each of them as Components - which is just a
        # NutrientVector with both Components.

        cA3plusB3 = JSON3.read("""{ "qty":"11g", "of":"Fat" }""",Component);
        @test string(cA3plusB3) == string(add(cA3,cB3));
    end

    @testset ExtendedTestSet "'add' NutrientVector operation" begin
        nvA = JSON3.read("""{
            "name":"A",
            "component":[
                { "qty":"100J", "of":"Energy" },
                { "qty":"3g", "of":"Protein" },
                { "qty":"4g", "of":"Fat" },
                { "#":"end" }
            ]
        }""", NutrientVector);
        # println(componentNames(nvA))
        @test componentNames(nvA) == String["Energy","Protein","Fat"]
        nvB = JSON3.read("""{
            "name":"B",
            "component":[
                { "qty":"80J", "of":"Energy" },
                { "qty":"2g", "of":"Carbs" },
                { "qty":"7g", "of":"Fat" },
                { "#":"end" }
            ]
        }""", NutrientVector);
        @test componentNames(nvB) == String["Energy","Carbs","Fat"]
        nvAplusB = JSON3.read("""{
            "name":"(A)+(B)",
            "component":[
                { "qty":"180J", "of":"Energy" },
                { "qty":"11g", "of":"Fat" },
                { "qty":"3g", "of":"Protein" },
                { "qty":"2g", "of":"Carbs" },
                { "#":"end" }
            ]
        }""", NutrientVector);
        @test componentNames(nvAplusB) == String["Energy","Fat","Protein","Carbs"]
        # println(componentsNamed(nvAplusB,"Energy"));

        # It's a matter of preference whether you want to compare a struct array by...
        # ...mapping string over it, or...
        @test map(string,componentsNamed(nvAplusB,"Energy")) == map(string,Component[JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component)])
        # @test map(string,componentsNamed(nvAplusB,"Energy")) == map(string,Component[JSON3.read("""{ "qty":"181J", "of":"Energy" }""",Component)])

        # ...string'ifying it as a whole
        @test string(componentsNamed(nvAplusB,"Energy")) == string(Component[JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component)])
        # @test string(componentsNamed(nvAplusB,"Energy")) == string(Component[JSON3.read("""{ "qty":"181J", "of":"Energy" }""",Component)])

        # Both probably have pros and cons, so get more experience with them to decide.

        @test string(nvAplusB) == string(add(nvA,nvB));

    end

end

#=

NutrientVector 'resolve' operation: (performed wrt a nutrientDatabase)

Recursively break down any components of a supplied nutrient vector
that have known decompositions (i.e., entries in the nutrientDatabase)
and keep collecting them all into an equivalent nutrient vector until
you reach one that is maximally resolved into its 'basis' vectors.

A 'basis' vector is one of two things.  It could be a genuine
primitive that doesn't have a further nutritionally meaningful
decomposition because it represents a single nutrient.  Or it could be
an ingredient or a meal or whatever other aggregate that could in
principle be nutritionally analysed but for which we in practice
either can't obtain such analysis or haven't yet included it into the
nutrientDatabase against which we are performing the resolution
operation.

Algorithm is as follows:

create a list of the names of all entries in the nutrientDatabase

while (there exists a component in the working nutrient vector that is in this list)
- remove this component from the working nutrient vector
- create a suitably scaled version from its definition in the nutrientDatabase
- add the resulting nutrient vector back to the working nutrient vector
end

Question: How do you ensure that the algorithm terminates?  You could
easily have mutually recursive definitions...

Answer: As soon as a loop is detected, don't try to resolve the
component in question any further.  Simply regard it as a 'basis'
vector.

Question: How do you detect a loop?

Bear in mind that the definitions in the nutrientDatabase are
themselves allowed to be defined with components that are defined
elsewhere in the nutrientDatabase.  A practical example of where this
is useful is to express standardised meals in terms of their
ingredients (where many different meals could use some of the same
ingredients) and also to include the nutritional analyses of the
ingredients.  A daily log could then easily contain multiple meals
(some perhaps repeated) and/or multiple individual ingredients.  so
entries at different levels of the hierarchy could potentially have to
be resolved multiple times.

Answer: So we don't necessarily have a loop if we resolve a component
with the same name more than once.  But we do have a loop (I think)
iff the resolution of a given component leads directly to the same
component again needing to be resolved.  So perhaps we could maintain
a "call stack" of the components that are currently being resolved,
and call foul if we see we have to resolve a component that is
currently in the call stack.

Question: But when that happens, the attempt to resolve it is detected
to be spurious and should be unwound to regard its entire contribution
to the overall result as a single 'basis' vector, and not a 'basis'
vector plus its non-self-referencing components.  How to accomplish
that?

Answer: Perhaps a good way could be to perform a full lookahead at
each component resolution step to see whether any of its descendent
components end up being itself. If they do, just regard it as a basis
vector and move on.  If they don't, do the iteration of the while loop
in the pseudocode above.

So, revised algorithm is as follows:

create a list of the names of all entries in the nutrientDatabase

while (there exists a component in the working nutrient vector that is in this list
       AND DOESN'T RECURSIVELY RESOLVE TO ITSELF)
- remove this component from the working nutrient vector
- create a suitably scaled version from its definition in the nutrientDatabase
- add the resulting nutrient vector back to the working nutrient vector
end

And the algorithm for detecting circular resolution is as follows:

SUGGESTION3: Find a Julia library that could have a ready built solution for you to use.
https://www.google.com/search?q=graph+algorithms+julia&oq=julia+graph+algortu&aqs=chrome.1.69i57j0i8i13i30.6338j0j7&sourceid=chrome&ie=UTF-8

eg https://github.com/JuliaGraphs/LightGraphs.jl
https://github.com/JuliaGraphs/LightGraphsExtras.jl
https://github.com/JuliaGraphs/JuliaGraphsTutorials
https://github.com/JuliaGraphs
https://juliagraphs.org/

SUGGESTION2: Follow up on https://stackoverflow.com/questions/261573/best-algorithm-for-detecting-cycles-in-a-directed-graph

SUGGESTION: Strongly consider a dynamic programming solution.

- Create a giant adjacency matrix of all pairs of entries in the
  nutrientDatabase, with all entries initially zero.

- If the definition of A

# note the top level name of the component
# call the definition of this component the working nutrient vector
#
# while (there exists a component in the working nutrient vector that is in the list of entries in the nutrientDatabase)
# - if the name of this component is the name of the top level component, we have our smoking gun, return true
# -
# end

2022-01-01:
So, after some investigation, the final solution will look as follows:

When attempting to resolve a NutrientVector into its basis components,
construct a MetaDiGraph with vertices representing NutrientVectors,
and a directed edge from vertex A to vertex B representing that B is a
component of A, with edge weight representing the quantity of
component B in A. Keep expanding the NutrientVector recursively,
passing the graph around and adding vertices and edges to it until
there are no more to add.

Then you have a MetaDiGraph representing the full situation.  And you
can check if it has any simplecycles().  If it does, then it can't be
meaningfully resolved, and the simplecycles found should just be given
to the user so that they can figure out what they've done wrong in
representing the NutrientVector and/or database of components.

If it doesn't have any simplecycles, then we can do a depth-first
traversal of the MetaDiGraph,

=#

if ALL || "graph" ∈ TESTS

    @testset ExtendedTestSet "NutrientVector MetaDiGraph functions" begin

        g = make_graph()
        add_vertex(g,"Log")
        @test string(list_frontier(g)) == string(["Log"]);
        add_vertex(g,"Item A")
        add_vertex(g,"Item B")
        add_vertex(g,"Item C")
        add_vertex(g,"Item D")
        @test string(list_frontier(g)) == string(["Log", "Item A", "Item B", "Item C", "Item D"]);
        add_vertex(g,"Basis I")
        add_vertex(g,"Basis J")
        add_vertex(g,"Basis K")
        @test string(list_frontier(g)) == string(["Log", "Item A", "Item B", "Item C", "Item D", "Basis I", "Basis J", "Basis K"]);
        add_edge(g,"Log","Item A","LA")
        add_edge(g,"Log","Item B","LB")
        add_edge(g,"Log","Item C","LC")
        add_edge(g,"Log","Item D","LD")
        @test string(list_frontier(g)) == string(["Item A", "Item B", "Item C", "Item D", "Basis I", "Basis J", "Basis K"]);
        add_edge(g,"Item A","Basis I","AI")
        add_edge(g,"Item A","Basis J","AJ")
        @test string(list_frontier(g)) == string(["Item B", "Item C", "Item D", "Basis I", "Basis J", "Basis K"]);
        add_edge(g,"Item B","Basis I","BI")
        add_edge(g,"Item B","Basis J","BJ")
        add_edge(g,"Item B","Basis K","BK")
        @test string(list_frontier(g)) == string(["Item C", "Item D", "Basis I", "Basis J", "Basis K"]);
        add_edge(g,"Item D","Basis K","DK")
        @test string(list_frontier(g)) == string(["Item C", "Basis I", "Basis J", "Basis K"]);

        # it should just fail gracefully when you add a vertex that already exists
        @test string(collect(vertices(g)))==string([1,2,3,4,5,6,7,8])
        add_vertex(g,"Log");
        @test string(collect(vertices(g)))==string([1,2,3,4,5,6,7,8])

        @test string(list_cycles(g)) == string([
        ])
        @test string(list_edges(g)) == string(Any[
            ["Log", "LA", "Item A"],
            ["Log", "LB", "Item B"],
            ["Log", "LC", "Item C"],
            ["Log", "LD", "Item D"],
            ["Item A", "AI", "Basis I"],
            ["Item A", "AJ", "Basis J"],
            ["Item B", "BI", "Basis I"],
            ["Item B", "BJ", "Basis J"],
            ["Item B", "BK", "Basis K"],
            ["Item D", "DK", "Basis K"],
        ])

        @test string(list_paths(g,"Log")) == string([
            ["Log", "LA", "Item A", "AI", "Basis I"],
            ["Log", "LA", "Item A", "AJ", "Basis J"],
            ["Log", "LB", "Item B", "BI", "Basis I"],
            ["Log", "LB", "Item B", "BJ", "Basis J"],
            ["Log", "LB", "Item B", "BK", "Basis K"],
            ["Log", "LC", "Item C"],
            ["Log", "LD", "Item D", "DK", "Basis K"],
        ])
#=

        add_edge(g,"Basis J","Basis K","JK")
        add_edge(g,"Basis K","Basis J","KJ")

        @test string(list_cycles(g)) == string(Any[
            ["Basis J", "Basis K"],
        ])

        try
            list_paths(g,"Log");
        catch e
            println(e)
        end

        add_edge(g,"Basis K","Basis K","KK")

        @test string(list_cycles(g)) == string(Any[
            ["Basis J", "Basis K"],
            ["Basis K"],
        ])
=#
    end

end

if ALL || "reduce_path" ∈ TESTS

    @testset ExtendedTestSet "NutrientVector reduce_path" begin

        nvEmpty = JSON3.read("""{
            "name":"Empty",
            "component":[]
        }""",NutrientVector)
        pathEmpty = ["Empty"]
        @test reduce_path(pathEmpty,Vector{NutrientVector}([])) == JSON3.read("""{}""", Component)

        LA=parseUnit("8g")
        LB=parseUnit("65g")
        LC=parseUnit("26g")
        LD=parseUnit("42g")
        nvLog = JSON3.read("""{
            "name":"Log",
            "component":[
                { "qty":"$(stringifyUnit(LA))", "of":"Item A" },
                { "qty":"$(stringifyUnit(LB))", "of":"Item B" },
                { "qty":"$(stringifyUnit(LC))", "of":"Item C" },
                { "qty":"$(stringifyUnit(LD))", "of":"Item D" },
                { "#":"end", "of":"" }
            ]
        }""",NutrientVector)

        AS=parseUnit("89g")
        AB=parseUnit("37g")
        AI=parseUnit("39kJ")
        AJ=parseUnit("40g")
        nvItemA = JSON3.read("""{
            "name":"Item A",
            "component":[
                { "qty":"$(stringifyUnit(AS))", "of":"serving" },
                { "qty":"$(stringifyUnit(AB))", "of":"Item B" },
                { "qty":"$(stringifyUnit(AI))", "of":"Basis I" },
                { "qty":"$(stringifyUnit(AJ))", "of":"Basis J" },
                { "#":"end" }
            ]
        }""",NutrientVector)

        BS=parseUnit("93g")
        BI=parseUnit("42kJ")
        BJ=parseUnit("43g")
        BK=parseUnit("35g")
        nvItemB = JSON3.read("""{
            "name":"Item B",
            "component":[
                { "qty":"$(stringifyUnit(BS))", "of":"serving" },
                { "qty":"$(stringifyUnit(BI))", "of":"Basis I" },
                { "qty":"$(stringifyUnit(BJ))", "of":"Basis J" },
                { "qty":"$(stringifyUnit(BK))", "of":"Basis K" },
                { "#":"end" }
            ]
        }""",NutrientVector)

        DS=parseUnit("56g")
        DK=parseUnit("74g")
        nvItemD = JSON3.read("""{
            "name":"Item D",
            "component":[
                { "qty":"$(stringifyUnit(DS))", "of":"serving" },
                { "qty":"$(stringifyUnit(DK))", "of":"Basis K" },
                { "#":"end" }
            ]
        }""",NutrientVector)
        show(nvItemD)
        nvDB = Vector{NutrientVector}([
            nvLog,
            nvItemA,
            nvItemB,
            nvItemD,
        ])
        #pathLAS = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AS))", "serving"]
        pathLABI = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AB))", "Item B", "$(stringifyUnit(BI))", "Basis I"]
        pathLABJ = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AB))", "Item B", "$(stringifyUnit(BJ))", "Basis J"]
        pathLABK = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AB))", "Item B", "$(stringifyUnit(BK))", "Basis K"]
        pathLAI = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AI))", "Basis I"]
        pathLAJ = ["Log", "$(stringifyUnit(LA))", "Item A", "$(stringifyUnit(AJ))", "Basis J"]
        #pathLBS = ["Log", "$(stringifyUnit(LB))", "Item B", "$(stringifyUnit(BS))", "serving"]
        pathLBI = ["Log", "$(stringifyUnit(LB))", "Item B", "$(stringifyUnit(BI))", "Basis I"]
        pathLBJ = ["Log", "$(stringifyUnit(LB))", "Item B", "$(stringifyUnit(BJ))", "Basis J"]
        pathLBK = ["Log", "$(stringifyUnit(LB))", "Item B", "$(stringifyUnit(BK))", "Basis K"]
        pathLC = ["Log", "$(stringifyUnit(LC))", "Item C"]
        #pathLDS = ["Log", "$(stringifyUnit(LD))", "Item D", "$(stringifyUnit(DS))", "serving"]
        pathLDK = ["Log", "$(stringifyUnit(LD))", "Item D", "$(stringifyUnit(DK))", "Basis K"]

        @test reduce_path(pathLABI,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LA/AS * AB/BS * BI))", "of":"Basis I" }""",Component)
        @test reduce_path(pathLABJ,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LA/AS * AB/BS * BJ))", "of":"Basis J" }""",Component)
        @test reduce_path(pathLABK,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LA/AS * AB/BS * BK))", "of":"Basis K" }""",Component)

        @test reduce_path(pathLAI,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LA/AS * AI))", "of":"Basis I" }""",Component)
        @test reduce_path(pathLAJ,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LA/AS * AJ))", "of":"Basis J" }""",Component)

        @test reduce_path(pathLBI,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LB/BS * BI))", "of":"Basis I" }""",Component)
        @test reduce_path(pathLBJ,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LB/BS * BJ))", "of":"Basis J" }""",Component)
        @test reduce_path(pathLBK,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LB/BS * BK))", "of":"Basis K" }""",Component)

        @test reduce_path(pathLDK,nvDB) == JSON3.read("""{ "qty":"$(stringifyUnit(LD/DS * DK))", "of":"Basis K" }""",Component)

    end

end

if ALL || "resolve" ∈ TESTS

    #=

    NutrientVector 'resolve' operation:

    Try to recursively expand the components of a supplied
    NutrientVector with respect to a supplied database of
    NutrientVectors, reporting problems with the use of this
    generalized setup if it occurs.

    =#

    @testset ExtendedTestSet "'resolve' NutrientVector operation" begin

        @testset ExtendedTestSet "'resolve' pathological cases" begin
            nvEmpty = JSON3.read("""{
                "name":"Empty",
                "component":[]
            }""",NutrientVector)
            nvResolvedEmpty = JSON3.read("""{
                "name":"resolved(Empty)",
                "component":[
                    { "#":"end" }
                ]
            }""",NutrientVector)
            @test stringifyNV(resolve(nvEmpty,Vector{NutrientVector}([]))) == stringifyNV(nvResolvedEmpty)

            nvA = JSON3.read("""{
                "name":"A",
                "component":[
                    { "qty":"10g", "of":"B" },
                    { "qty":"15g", "of":"C" },
                    { "#":"end" }
                ]
            }""", NutrientVector);
            nvResolvedA = JSON3.read("""{
                "name":"resolved(A)",
                "component":[
                    { "qty":"10g", "of":"B" },
                    { "qty":"15g", "of":"C" },
                    { "#":"end" }
                ]
            }""", NutrientVector);
            @test stringifyNV(resolve(nvA,Vector{NutrientVector}([]))) == stringifyNV(nvResolvedA)
            @test stringifyNV(resolve(nvA,Vector{NutrientVector}([nvA]))) == stringifyNV(nvResolvedA)
            @test stringifyNV(resolve(nvA,Vector{NutrientVector}([nvA,nvA]))) == stringifyNV(nvResolvedA)

            nvB = JSON3.read("""{
                "name":"B",
                "component":[
                    { "qty":"1g", "of":"A" },
                    { "#":"end" }
                ]
            }""", NutrientVector);
            nvResolvedB = JSON3.read("""{
                "name":"resolved(B)",
                "component":[
                    { "qty":"1g", "of":"A" },
                    { "#":"end" }
                ]
            }""", NutrientVector);
            @test stringifyNV(resolve(nvB,Vector{NutrientVector}([]))) == stringifyNV(nvResolvedB)
            @test stringifyNV(resolve(nvB,Vector{NutrientVector}([nvB]))) == stringifyNV(nvResolvedB)
            @test stringifyNV(resolve(nvB,Vector{NutrientVector}([nvB,nvB]))) == stringifyNV(nvResolvedB)

            nvC = JSON3.read("""{
                "name":"C",
                "component":[
                    { "qty":"1g", "of":"C" },
                    { "#":"end" }
                ]
            }""", NutrientVector);
            @test_throws ResolveException("encountered cycles Any[['C']]") resolve(nvC,Vector{NutrientVector}([]))
            @test_throws ResolveException("encountered cycles Any[['C']]") resolve(nvC,Vector{NutrientVector}([nvC]))
            @test_throws ResolveException("encountered cycles Any[['C']]") resolve(nvC,Vector{NutrientVector}([nvC,nvC]))

            @test_throws ResolveException("encountered cycles Any[['C'],['A','B']]") resolve(nvA,Vector{NutrientVector}([nvB,nvC]))
            @test_throws ResolveException("encountered cycles Any[['C'],['A','B']]") resolve(nvA,Vector{NutrientVector}([nvA,nvB,nvC]))

            # quantities of duplicated entries should accumulate
            nvD = JSON3.read("""{
                "name":"D",
                "component":[
                    { "qty":"1g", "of":"Duplicated" },
                    { "qty":"2g", "of":"Singular" },
                    { "qty":"3g", "of":"Duplicated" },
                    { "#":"end" }
                ]
            }""",NutrientVector);
            nvResolvedD = JSON3.read("""{
                "name":"resolved(D)",
                "component":[
                    { "qty":"4g", "of":"Duplicated" },
                    { "qty":"2g", "of":"Singular" },
                    { "#":"end" }
                ]
            }""",NutrientVector);
            @test stringifyNV(resolve(nvD,Vector{NutrientVector}([]))) == stringifyNV(nvResolvedD)
            
        end

        @testset ExtendedTestSet "'resolve' happy path" begin

            nvLog = JSON3.read("""{
                "name":"Log",
                "component":[
                    { "qty":"10g", "of":"Entry1" },
                    { "qty":"15g", "of":"Entry2" },
                    { "#":"end" }
                ]
            }""", NutrientVector);

            nvEntry1 = JSON3.read("""{
                "name":"Entry1",
                "component":[
                    { "qty":"100g", "of":"serving" },
                    { "qty":"10g", "of":"NutrientA" },
                    { "qty":"15g", "of":"NutrientB" },
                    { "#":"end" }
                ]
            }""", NutrientVector);

            nvEntry2 = JSON3.read("""{
                "name":"Entry2",
                "component":[
                    { "qty":"100g", "of":"serving" },
                    { "qty":"5g", "of":"NutrientA" },
                    { "qty":"1g", "of":"NutrientB" },
                    { "qty":"3g", "of":"NutrientC" },
                    { "#":"end" }
                ]
            }""", NutrientVector);

            nvResolvedLog = JSON3.read("""{
                "name":"resolved(Log)",
                "component":[
                    { "qty":"1.75g", "of":"NutrientA" },
                    { "qty":"1.65g", "of":"NutrientB" },
                    { "qty":"0.44999999999999996g", "of":"NutrientC" },
                    { "#":"end" }
                ]
            }""", NutrientVector);

            # FIXME: resolve the rounding error issue: should be 0.45g of NutrientC
            # FIXME: does it make sense for serving to be in the picture?

            @test stringifyNV(resolve(nvLog,Vector{NutrientVector}([nvEntry1,nvEntry2]))) == stringifyNV(nvResolvedLog)
        end
    end
end
