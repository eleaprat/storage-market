## Run for the whole time period

ps_init = Dict()
for s in 1:nb_s
    ps_init[s] = S_df[s, "SOC Init"]
end

include("ideal_fct.jl")
obj_tot, ps_tot, ec_tot, ed_tot, revenues_tot = mc_storage_ideal(nb_t_tot)

cum_rev_tot = [float(0)]
cum_rev = 0
for t in 1:nb_t_tot
    global cum_rev_tot, cum_rev
    cum_rev += revenues_tot[t]
    cum_rev_tot = append!(cum_rev_tot,cum_rev)
end


plot(T_tot,pushfirst!(ps_tot["S1",:].data,ps_init[1]), label="Stored - total")
plot!(T_tot,pushfirst!(ec_tot["S1",:].data,0), label="Charged - total")
plot!(T_tot,pushfirst!(ed_tot["S1",:].data,0), label="Discharged - total")

nb_d = 2
t_per_d = 24
t_init = 1
obj_per_d = []
ps_per_d = []
ec_per_d = []
ed_per_d = []
ps_init_d = ps_init

cum_rev_d = [float(0)]
cum_rev_tp = 0

for d in 1:nb_d
    global t_init, ps_init_d, obj_per_d, ps_per_d, ec_per_d, ed_per_d, t_per_d
    obj_d, ps_d, ec_d, ed_d, revenues_d = mc_storage_ideal(t_init, t_per_d, ps_init_d)
    obj_per_d = push!(obj_per_d,obj_d)
    ps_per_d = append!(ps_per_d,ps_d["S1",:].data)
    ec_per_d = append!(ec_per_d,ec_d["S1",:].data)
    ed_per_d = append!(ed_per_d,ed_d["S1",:].data)
    t_end = t_init + t_per_d - 1
    t_init = t_end + 1
    if t_init <= nb_t_tot
        ps_init_d = Dict()
        for s in 1:nb_s
            ps_init_d[s] = ps_d["S$s", "T$t_end"]
        end
    end

    for t in 1:t_per_d
        global cum_rev_d, cum_rev_tp
        cum_rev_tp += revenues_d[t]
        cum_rev_d = append!(cum_rev_d,cum_rev_tp)
    end
end

plot!(T_tot,pushfirst!(ps_per_d,ps_init[1]), label="Stored - separated", linestyle=:dash, linecolor=:deepskyblue3)
plot!(T_tot,pushfirst!(ec_per_d,0), label="Charged - separated", linestyle=:dash, linecolor=:orangered2)
plot!(T_tot,pushfirst!(ed_per_d,0), label="Discharged - separated", linestyle=:dash, linecolor=:seagreen)

savefig("State of charge")

plot(T_tot,cum_rev_tot, label="Cumulative revenues - total")
plot!(T_tot, cum_rev_d, label="Cumulative revenues - separated", linestyle=:dash)

savefig("Revenues")

plot(T_tot, cum_rev_tot-cum_rev_d, legend = false)
savefig("Revenues_diff")
