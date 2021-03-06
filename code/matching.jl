using JuMP, Gurobi
using CSV, DataFrames

"""
Calculates the inverse of the covariance matrix of a matrix
- `df` The matrix we wish to calculate covariance for, as a DataFrame
"""
function inv_cov(df::DataFrame)::Matrix{Float64}
    mat = Matrix(df)
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
- `distance` Distance matrix dictionary of size (treated x control) with keys (treated ID, control ID)
             Note: Distances for matches that are impossible should be a very large number
- `balance`  Balance matrix dictionary of size ((treated+control) x k) where k is the number of
             covariates for which we desire exact match. Has keys (subject ID, k). Individual entries are 
             values of the k binary covariates for that particular subject 
- `numsets`  Number of matched pairs we want
- `lambda`   Penalty assessed for violating fine balance, typically will be the sum of all distances in distance matrix
"""
function brs_matching(distance, balance, numsets)
    #Define match Model
    m = Model(
        optimizer_with_attributes(
            Gurobi.Optimizer, "Presolve" => 0, "OutputFlag" => 0, "NodefileStart" => 0.1, "Threads" => 1,
        )
    )
    
    # Constants
    ### Vectors of treated and control individuals
    edges = keys(distance)
    treated = unique(first.(edges))
    control = unique(last.(edges))
    treated_control = unique(vcat(treated,control))

    ### Vector of balance covariates
    bcov = unique(last.(keys(balance)))

    ### Lambda - the penalty for breaking balance
    lambda = sum(values(distance))+1

    # Variables
    @variables(m, begin
        f[edges], Bin # 1 if edge exists, 0 if edge does not
        pg[bcov] >= 0 # Positive gap between treated and control 
        ng[bcov] >= 0 # Negative gap between treated and control
    end)

    # Constraints
    ### There are a total of S sets
    @constraint(m, sum(f[i] for i in edges) >= numsets)
    ### Each person is in at most 1 set
    @constraint(m, a[i in treated_control], 
        (sum(f[(i,j)] for j in control if (i,j) in edges) + 
        sum(f[(j,i)] for j in treated if (j,i) in edges)) 
        <= 1) 
    ### Enforces perfect balance
    @constraint(m, c[k in bcov], sum(f[(i,j)]*balance[i,k] - f[(i,j)]*balance[j,k] 
        for i in treated, j in control
        if (i,j) in edges)  
        <= pg[k])
    @constraint(m, c2[k in bcov], sum(f[(i,j)]*balance[j,k] - f[(i,j)]*balance[i,k] 
        for i in treated, j in control
        if (i,j) in edges) 
        <= ng[k])

    # Objective
    @objective(m, Min, sum(f[i] * distance[i] for i in edges) + sum(lambda*(pg[k]+ng[k]) for k in bcov))
    optimize!(m)

    # Check if we actually found a solution
    val = objective_value(m)
    val < Inf || error("This matching is infeasible.")

    # Return Sx2 matrix of the IDs in the matched pair
    assignment = [ i for i in edges if (JuMP.value(f[i])) > 0]
    return assignment
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

"""
Finds the first wave for a given subject
- `d` A the data dictionary
- `ID` the HHIDPN
"""
function wavelookup(d::Dict, ID::Int64)
    #Get all the possible waves
    waves = sort(unique(getindex.(keys(d),2)))
    for w in waves
        #Return the first wave for which ID has data
        if haskey(d, (ID,w))
            return w
        end
    end
    error("LookupError: This ID isn't in dictionary.")
end

function main()

    #This allows us to read the data in 
    script_location = @__DIR__
    df = CSV.read(string(script_location,"/../data/data-stacked.csv"))

    #Remove the categorized wealth and income covariates for matching
    variables = names(df)[1:43]
    df = df[!, variables]

    #Create dictionaries
    wsdict = Dict(r[:HHIDPN] => r[:FIRST_WS] for r in eachrow(unique(df[:,[:HHIDPN, :FIRST_WS]])))    
    datadict = Dict( (r[:HHIDPN], r[:W])::Tuple{Int64,Int64} => Vector(r[Not([:HHIDPN, :FIRST_WS, :W])])::Vector{Float64} for r in eachrow(df))
    treated = [ i for i in keys(wsdict) if wsdict[i] != -1 ]
    ### If someone experiences wage shock in first year (2) then they can't be control
    control = [i for i in keys(wsdict) if wsdict[i] != 2] 

    #Build the balance matrix/dictionary on column #22 - gender, #14 - ever smoke at baseline, #23 hispanic, #13 initial earnings, #29 = initial wealth, 30 = initial income
    #datadict[j,2][23] == The 23rd covariate in the 2nd year for the jth control
    balance_cov = [14]
    balancedict = Dict( (j,i) => datadict[j,wavelookup(datadict,j)][i] for j in keys(wsdict), i in balance_cov)
    
    #Calculate the distance matrix as a dictionary -- if match is impossible not in dictionary
    S = inv_cov(df[:, Not([:HHIDPN, :FIRST_WS, :W])])
    distancedict = Dict( (i, j) => pairwise_mahalanobis(i, j, S, df, wsdict, datadict) 
        for i in treated, j in control 
        if pairwise_mahalanobis(i, j, S, df, wsdict, datadict) < 1e14)

    # Perform the matching for the maximum number of possible sets;
    sets_count = sum([(t,wsdict[t]) in keys(datadict) for t in treated])
    match = brs_matching(distancedict,balancedict,sets_count) 
    CSV.write(string(script_location,"/../data/matched-pairs.csv"), DataFrame(match), header = ["treated","control"])
      
end
