using JuMP, Gurobi
using CSV, DataFrames

"""
Calculates the inverse of the covariance matrix of a matrix
- `df` The matrix we wish to calculate covariance for, as a DataFrame
"""
function inv_cov(df::DataFrame)::Matrix{Float64}
    mat = Matrix(df[:, Not([:HHIDPN, :FIRST_WS, :W])])
    return inv(mat' * mat)
end

"""
Calculates the Mahalanobis distance between a treated and potential control
- `trt` The ID of the treated individual
- `ctrl` The ID of the potential control
- `S` Inverse covariance matrix, calculated via inv_cov function
- `df` DataFrame
- `wsdict` Dictionary of first wage shock (treatment) for each person. Takes -1 if they never experienced treatment
- `datadict` Dictionary of data
- `LARGE_DIST` Distance that indicates the match is impossible
"""
function pairwise_mahalanobis(trt::Int64, ctrl::Int64, S::Matrix{Float64}, df::DataFrame, wsdict::Dict, datadict::Dict; LARGE_DIST ::Float64 = 1e14)::Float64
    #If someone would be matched to themselves, return large distance
    if trt == ctrl
        return LARGE_DIST
    end
    
    #Else, get the wave that the treated experienced treatment
    wave = get(wsdict, trt, -2)
    wave != -2 || error("trt not found")

    #See if the control was ever treated
    cwave = get(wsdict, ctrl, -2)
    cwave != -2 || error("ctrl not found")

    # if control is already treated, we cannot match
    if cwave != -1 && cwave <= wave
        return LARGE_DIST
    end

    #Get the covariates that the treated and control will match on
    trow::Union{Nothing,Vector{Float64}} = get(datadict, (trt,wave)::Tuple, nothing)
    crow::Union{Nothing,Vector{Float64}} = get(datadict, (ctrl,wave)::Tuple, nothing)

    #If the treated/control don't have data (i.e. missing covariates), we cannot match.
    if trow === nothing || crow === nothing
        return LARGE_DIST
    end

    #Otherwise, this is a valid distance, calculate covariate distance
    d::Vector{Float64} = trow - crow

    #Multiply by inverse of covariance matrix
    return d' * S * d
end

"""
Uses JuMP to perform balanced risk set matching 
- `treated`  Vector of IDs of treated pool
- `control`  Vector of IDs of match pool
- `distance` Function used to calculate distance between treated and control
- `numsets`  Number of matched pairs we want
"""
function brs_matching(treated,control,distance,numsets)#; args...)
    #Define match Model
    m = Model(with_optimizer(Gurobi.Optimizer, Presolve=0, OutputFlag=1, NodefileStart=0.5))
    
    #Below variable takes 1 if edge exists, 0 if edge does not
    @variable(m, f[treated,control], Bin)

    # Each person is in at most 1 set
    @constraint(m, a[j in control], sum(f[i,j] for i in treated) <= 1 )
    @constraint(m, a2[i in treated], sum(f[i,j] for j in control) <= 1 )

    # Each person is not matched to themself
    #@constraint(m, sum(x[i,i] for i in treated, i in control) <= 0)

    #There are a total of S sets
    @constraint(m, sum(f[i,j] for i in treated, j in control) >= numsets)

    @objective(m, Min, sum(f[i,j] * distance(i,j,S,df,wsdict,datadict) for i in treated, j in control ))

    optimize!(m)

    val = objective_value(m)

    val < LARGE_DIST || error("infeasible")

    assignment = [ (JuMP.value(f[i,j])) for i in treated, j in control ]

    return matched_sets(treated,control,assignment)
end

"""
Takes output from JuMP and makes a matrix of matches
- `treated` Vector of IDs of treated pool
- `control` Vector of IDs of match pool
- `amat` Matrix of assignments of edges between treated and control
"""
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

function main()

    #LARGE_DIST is used for impossible matches
    LARGE_DIST = 1e14

    #This allows us to read the data in 
    script_location = @__DIR__
    df = CSV.read(string(script_location,"/../data/data-stacked.csv"))

    #Create dictionaries
    wsdict = Dict(r[:HHIDPN] => r[:FIRST_WS] for r in eachrow(unique(df[:,[:HHIDPN, :FIRST_WS]])))    
    datadict = Dict( (r[:HHIDPN], r[:W])::Tuple{Int64,Int64} => Vector(r[Not([:HHIDPN, :FIRST_WS, :W])])::Vector{Float64} for r in eachrow(df) )
    treated = [ i for i in keys(wsdict) if wsdict[i] != -1 ]
    control = collect(keys(wsdict))

    # count the number of matchable treated subjects
    count = sum([(t,wsdict[t]) in keys(datadict) for t in treated])
    
    #Perform the matching and write to CSV
    S = inv_cov(df)
    match = brs_matching(treated,control,pairwise_mahalanobis,count)
    CSV.write("../data/matched-pairs.csv", DataFrame(match), writeheader=false)
      
end

