using JuMP, Clp, NamedArrays

function matching(treated,control,distances,S)
    #Define match Model
    m = Model(with_optimizer(Clp.Optimizer, LogLevel=1, Algorithm=4))
    #Below variable takes 1 if edge exists, 0 if edge does not
    @variable(m, f[treated,control] >= 0)

    # Each person is in at most 1 set
    @constraint(m, a[j in control], sum(f[i,j] for i in treated) <= 1 )
    @constraint(m, a2[i in treated], sum(f[i,j] for j in control) <= 1 )

    # Each person is not matched to themself
    #@constraint(m, sum(x[i,i] for i in treated, i in control) <= 0)

    #There are a total of S sets
    @constraint(m, sum(f[i,j] for i in treated, j in control) >= S)

    @objective(m, Min, sum(f[i,j]*distances[i,j] for i in treated, j in control ))

    optimize!(m)

    assignment = NamedArray( [ (JuMP.value(f[i,j])) for i in treated, j in control ], (treated, control), ("treated","control"))

    return assignment
end

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