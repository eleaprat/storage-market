function mc_storage_final(t_start, nb_t, ps_init, ps_final)

    t_end = t_start+(nb_t-1)
    T = ["T$i" for i in t_start:t_end]

    ## Parameters

    G_param = Dict()
    for g in 1:nb_g
        for t in t_start:t_end
            local p_min = G_df[t, "G$g - Min"]
            local p_max = G_df[t, "G$g - Max"]
            local c = G_df[t, "G$g - Cost"]
            G_param["G$g","T$t"] = conv_struct(p_min, p_max, c)
        end
    end

    W_param = Dict()
    for w in 1:nb_w
        for t in t_start:t_end
            local p_min = W_df[t, "W$w - Min"]
            local p_max = W_df[t, "W$w - Max"]
            local c = W_df[t, "W$w - Cost"]
            W_param["W$w","T$t"] = conv_struct(p_min, p_max, c)
        end
    end

    L_param = Dict()
    for l in 1:nb_l
        for t in t_start:t_end
            local p_min = L_df[t, "L$l - Min"]
            local p_max = L_df[t, "L$l - Max"]
            local c = L_df[t, "L$l - Price"]
            L_param["L$l","T$t"] = conv_struct(p_min, p_max, c)
        end
    end

    S_param = Dict()
    for s in 1:nb_s
        local p_min = S_df[s, "Min"]
        local p_max = S_df[s, "Max"]
        local α_c = S_df[s, "Charge Efficiency"]
        local α_d = S_df[s, "Discharge Efficiency"]
        local p_init = ps_init[s]
        local p_end = ps_final[s]
        local p_c_max = S_df[s, "Charge max"]
        local p_d_max = S_df[s, "Discharge max"]
        S_param["S$s"] = strg_struct(p_min, p_max, α_c, α_d, p_init, p_end, p_c_max, p_d_max)
    end

    ## Optimization model

    model = Model(GLPK.Optimizer)

    @variables model begin
         e_G[g in G, t in T]
         e_L[l in L, t in T]
         e_W[w in W, t in T]
         p_S[s in S, t in T]
         e_C[s in S, t in T] >= 0
         e_D[s in S, t in T] >= 0
     end

    @objective(model, Min,
     sum(G_param[g,t].c*e_G[g,t] for g in G, t in T)+sum(W_param[w,t].c*e_W[w,t] for w in W, t in T)-sum(L_param[l,t].c*e_L[l,t] for l in L, t in T))

     @constraints model begin
        PowerBalance[t in T],
            sum(e_G[g, t] for g in G) + sum(e_W[w, t] for w in W) + sum(e_D[s, t] for s in S) - sum(e_L[l, t] for l in L) - sum(e_C[s, t] for s in S)== 0
        StorageBalance[s in S, t in T[2:end]],
            p_S[s,t] == p_S[s,T[findall( x -> x == t , T)[1]-1]] + 1/∆t * (S_param[s].α_c * e_C[s,t] - (1/S_param[s].α_d) * e_D[s,t])
        StorageBalance_init[s in S],
            p_S[s,T[1]] == S_param[s].s_init + 1/∆t * (S_param[s].α_c * e_C[s,T[1]] - (1/S_param[s].α_d) * e_D[s,T[1]])
        Storage_end[s in S],
            p_S[s,T[end]] == S_param[s].s_end
        Gen_min[g in G, t in T],
            e_G[g,t] >= ∆t * G_param[g,t].p_min
        Gen_max[g in G, t in T],
            e_G[g,t] <= ∆t * G_param[g,t].p_max
        Wind_min[w in W, t in T],
            e_W[w,t] >= ∆t * W_param[w,t].p_min
        Wind_max[w in W, t in T],
            e_W[w,t] <= ∆t * W_param[w,t].p_max
        Load_min[l in L, t in T],
            e_L[l,t] >= ∆t * L_param[l,t].p_min
        Load_max[l in L, t in T],
            e_L[l,t] <= ∆t * L_param[l,t].p_max
        Stg_min[s in S, t in T],
            p_S[s,t] >= S_param[s].s_min
        Stg_max[s in S, t in T],
            p_S[s,t] <= S_param[s].s_max
        Charge_max[s in S, t in T],
            e_C[s,t] <= ∆t * S_param[s].p_c_max
        Discharge_max[s in S, t in T],
            e_D[s,t] <= ∆t * S_param[s].p_d_max
    end

    @time optimize!(model)
    status = termination_status(model)
    println(status)
    println(raw_status(model))

    @info("Model status ---> $(status)")

    obj = JuMP.objective_value(model)
    p_S_val = round.(JuMP.value.(p_S), digits=2)
    e_C_val = round.(JuMP.value.(e_C), digits=2)
    e_D_val = round.(JuMP.value.(e_D), digits=2)
    e_L_val = round.(JuMP.value.(e_L), digits=2)
    e_G_val = round.(JuMP.value.(e_G), digits=2)
    e_W_val = round.(JuMP.value.(e_W), digits=2)
    λ_val = round.(JuMP.dual.(PowerBalance), digits=2)

    load_shed = []
    social_welfare=[]
    for t in T
        load_shed = append!(load_shed, sum(L_param[l,t].p_max - e_L_val[l,t] for l in L))
        social_welfare = append!(social_welfare,-sum(G_param[g,t].c*e_G_val[g,t] for g in G)-sum(W_param[w,t].c*e_W_val[w,t] for w in W)+sum(L_param[l,t].c*e_L_val[l,t] for l in L))
    end

    return obj, p_S_val, e_C_val, e_D_val, social_welfare, load_shed, λ_val
end
