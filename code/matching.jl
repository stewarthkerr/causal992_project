using JuMP, Gurobi
using CSV, DataFrames, DataFramesMeta

#df = CSV.read("../data/data-stacked.csv")
#distance = CSV.read("../data/distance-matrix.csv")

function inv_cov(df::DataFrame)::Matrix{Float64}
    mat = Matrix(df[:, Not([:HHIDPN, :FIRST_WS, :W])])
    inv(mat' * mat)
end

# for calculating the distance
function match_dist(trt::Integer, ctrl::Integer, S::Matrix, df::DataFrame, wsdict::Dict)::Float64
    if trt == ctrl
        return 1e14
    end
    
    wave = get(wsdict, trt, -2)
    wave != -2 || error("trt not found")

    cwave = get(wsdict, ctrl, -2)
    cwave != -2 || error("ctrl not found")

    # if control is already treated
    if cwave != -1 && cwave <= wave
        return 1e14
    end

    trow = @where(df, :HHIDPN .== trt, :W .== wave)
    crow = @where(df, :HHIDPN .== ctrl, :W .== wave)

    numtrt = nrow(trow)
    numctrl = nrow(crow)

    (numtrt <= 1) && (numctrl <= 1) || error("$numtrt, $numctrl, $trt, $ctrl, $wave")

    if numctrl == 0 || numtrt == 0
        return 1e14
    end
    t = Vector(trow[1,:][Not([:HHIDPN, :FIRST_WS, :W])])
    c = Vector(crow[1,:][Not([:HHIDPN, :FIRST_WS, :W])])
    d = t - c

    return d' * S * d
end

#S = inv_cov(df)
#wsdict = Dict(r[:HHIDPN] => r[:FIRST_WS] for r in eachrow(unique(df[:,[:HHIDPN, :FIRST_WS]])))
#match_dist(45943010, 57894020, S, df, wsdict)

#treated = [ i for i in keys(wsdict) if wsdict[i] != -1 ]
#control = [ i for i in keys(wsdict)]

function matching(treated,control,distance,numsets,wsdict)
    #Define match Model
    m = Model(with_optimizer(Gurobi.Optimizer, Presolve=0, OutputFlag=1))
    #Below variable takes 1 if edge exists, 0 if edge does not
    @variable(m, f[treated,control], Bin)

    # Each person is in at most 1 set
    @constraint(m, a[j in control], sum(f[i,j] for i in treated) <= 1 )
    @constraint(m, a2[i in treated], sum(f[i,j] for j in control) <= 1 )

    # Each person is not matched to themself
    @constraint(m, sum(f[i,i] for i in treated) <= 0)

    #There are a total of S sets
    @constraint(m, sum(f[i,j] for i in treated, j in control) >= numsets)

    @objective(m, Min, sum(f[i,j] * distance(i,j,S,df,wsdict) for i in treated, j in control ))

    optimize!(m)

    assignment = [ (JuMP.value(f[i,j])) for i in treated, j in control ]

    return assignment
end

function matchingWithDist(df,distance,numsets)
    wsdict = Dict(r[:HHIDPN] => r[:FIRST_WS] for r in eachrow(unique(df[:,[:HHIDPN, :FIRST_WS]])))
    treated_keys = [ i for i in keys(wsdict) if wsdict[i] != -1 ]
    control_keys = [ i for i in keys(wsdict)]

    treated = collect(1:length(treated_keys))
    control = collect(1:length(control_keys))

    #Define match Model
    m = Model(with_optimizer(Gurobi.Optimizer, Presolve=0, OutputFlag=1))
    #Below variable takes 1 if edge exists, 0 if edge does not
    @variable(m, f[treated,control], Bin)

    # Each person is in at most 1 set
    @constraint(m, a[j in control], sum(f[i,j] for i in treated) <= 1 )
    @constraint(m, a2[i in treated], sum(f[i,j] for j in control) <= 1 )

    # Each person is not matched to themself
    @constraint(m, sum(f[i,i] for i in treated) <= 0)

    #There are a total of S sets
    @constraint(m, sum(f[i,j] for i in treated, j in control) >= numsets)

    @objective(m, Min, sum(f[i,j] * distance[i,j] for i in treated, j in control ))

    optimize!(m)

    assignment = [ (JuMP.value(f[i,j])) for i in treated, j in control ]

    return assignment
end

#=
function matchingExample()
    #Vector of treated individuals
    treated = collect(1:10)
    #Vector of control pool
    control = collect(1:50)
    #Number of desired matched sets
    S = length(treated)
    #Matrix of distances
    raw = randn(length(treated),length(control))
    distances = NamedArray( raw, (treated,control), ("treated","control"))

    x = matching(treated,control,distances,S)
    for i in 1:length(treated)
        print("\nSubject $i is matched to Control $(argmax(x[i,:]))")
    end
end
=#

#Need to clean this later
function createDistMatrix(treated,control,DIST)
    global trt_iter = 1
    for i in treated
        control_iter = 1
        for j in control
            DIST[trt_iter,control_iter] = match_dist(i,j,S, df, wsdict)
            control_iter = control_iter + 1
        end
        global trt_iter = trt_iter + 1
    end  
end