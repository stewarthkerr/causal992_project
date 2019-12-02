using JuMP, Gurobi
using CSV, DataFrames

function inv_cov(df::DataFrame)::Matrix{Float64}
    mat = Matrix(df[:, Not([:HHIDPN, :FIRST_WS, :W])])
    inv(mat' * mat)
end

# for calculating the distance
function match_dist(trt::Int64, ctrl::Int64, S::Matrix{Float64}, df::DataFrame, wsdict::Dict, datadict::Dict, LARGE_VAL::Float64)::Float64
    if trt == ctrl
        return LARGE_VAL
    end
    
    wave = get(wsdict, trt, -2)
    wave != -2 || error("trt not found")

    cwave = get(wsdict, ctrl, -2)
    cwave != -2 || error("ctrl not found")

    # if control is already treated
    if cwave != -1 && cwave <= wave
        return LARGE_VAL
    end

    trow::Union{Nothing,Vector{Float64}} = get(datadict, (trt,wave)::Tuple, nothing)
    crow::Union{Nothing,Vector{Float64}} = get(datadict, (ctrl,wave)::Tuple, nothing)

    if trow == nothing || crow == nothing
        return LARGE_VAL
    end
    d::Vector{Float64} = trow - crow

    return d' * S * d
end

function matched_sets(treated, control, amat::Matrix)
    set = Vector{Tuple{Int64,Int64}}(undef, 0)
    for i in 1:length(treated)
        for j in 1:length(control)
            if amat[i,j] != 0.
                push!(set, (treated[i],control[j]))
            end
        end
    end

    return set
end

function matching(treated,control,distance,numsets)
    #Define match Model
    m = Model(with_optimizer(Gurobi.Optimizer, Presolve=0, OutputFlag=1))
    #Below variable takes 1 if edge exists, 0 if edge does not
    @variable(m, f[treated,control], Bin)

    # Each person is in at most 1 set
    @constraint(m, a[j in control], sum(f[i,j] for i in treated) <= 1 )
    @constraint(m, a2[i in treated], sum(f[i,j] for j in control) <= 1 )

    # Each person is not matched to themself
    #@constraint(m, sum(x[i,i] for i in treated) <= 0)

    #There are a total of S sets
    @constraint(m, sum(f[i,j] for i in treated, j in control) >= numsets)

    @objective(m, Min, sum(f[i,j]* distance(i,j,S,df,wsdict,datadict) for i in treated, j in control ))

    optimize!(m)

    val = objective_value(m)

    val < LARGE_VAL || error("infeasible")

    assignment = [ (JuMP.value(f[i,j])) for i in treated, j in control ]

    return matched_sets(treated,control,assignment)
end

function main()
    LARGE_VAL = 1e14
    df = CSV.read("../data/data-stacked.csv")
    #Below for windows
    #df = CSV.read("..\\data\\data-stacked.csv")

    S = inv_cov(df)
    wsdict = Dict(r[:HHIDPN] => r[:FIRST_WS] for r in eachrow(unique(df[:,[:HHIDPN, :FIRST_WS]])))
    datadict = Dict( (r[:HHIDPN], r[:W])::Tuple{Int64,Int64} => Vector(r[Not([:HHIDPN, :FIRST_WS, :W])])::Vector{Float64} for r in eachrow(df) )
    
    treated = [ i for i in keys(wsdict) if wsdict[i] != -1 ]
    control = collect(keys(wsdict))

    #869 is the maximum number of matches we can have
    match = matching(treated,control,match_dist,869)

    #CSV.write("../data/matched-sets.csv", DataFrame(match), writeheader=false)
    #Below for windows
    #CSV.write("..\\data\\matched-sets.csv", DataFrame(match), writeheader=false)
    return match
end
