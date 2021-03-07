module Nutrinfo
using Reexport
@reexport using IntervalArithmetic
@reexport using Unitful
@reexport using DataStructures

#=

Takes an ingredient (which is a Dictionary mapping nutrients/energy to
quantities) and a servingSize, and creates a new Dictionary mapping
nutrients/energy to quantities which represents the ingredient scaled
by the supplied serving size relative to the servingSize mapping entry
it contains.

=#
function qty(serving,ingredient)
    ratio = serving/ingredient["Serving"];
    return SortedDict( key=>value*ratio for (key,value) in ingredient);
end

export qty;

end
