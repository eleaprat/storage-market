using JuMP, GLPK
using CSV, DataFrames
using Plots
using DataStructures

mutable struct conv_struct
    p_min; p_max; c
end

mutable struct strg_struct
    s_min; s_max; α_c; α_d; s_init; s_end; p_c_max; p_d_max
end

## Retrieve data

### Generators
G_df = CSV.read("Generation_Data.csv", DataFrame)

### Loads
L_df = CSV.read("Load_Data.csv", DataFrame)

### Wind
W_df = CSV.read("Wind_Data.csv", DataFrame)

### Storage
S_df = CSV.read("Storage_Data.csv", DataFrame)

nb_g = 1
nb_l = 1
nb_w = 1
nb_s = 1
#nb_t_tot = nrow(G_df)
#nb_d = div(nb_t_tot,24)
nb_d_max = 25
nb_d_test = 300
∆t = 1 # Time steps of 1 hour
t_per_d = div(24,∆t)

## Create Sets

G = ["G$i" for i in 1:nb_g]
L = ["L$i" for i in 1:nb_l]
W = ["W$i" for i in 1:nb_w]
S = ["S$i" for i in 1:nb_s]

#T_tot = ["T$i" for i in 0:nb_t_tot]
#T_d = ["T$i" for i in 0:24]

D_run = [i for i in 1:nb_d_test]
D_str = ["$i" for i in 1:nb_d_test]
D_horizon = [(nb_d_max+1)-i for i in 1:nb_d_max]
D_horizon_str = ["$i" for i in D_horizon]

include("final_level_fct.jl")

# Initialization
nb_t = nb_d_max * t_per_d # Length of the horizon

ps_init = []
ps_final = []
for s in nb_s
    global ps_init, ps_final
    ps_init = append!(ps_init, S_df[s, "SOC Init"])
    ps_final = append!(ps_final, S_df[s, "SOC End"])
end
sw_vs_horizon = []

for h in D_horizon # For each horizon length
    global nb_t, sw_cum_max, sw_vs_horizon

    t_start = 1
    ps_start = ps_init
    sw_cum = []
    sw_cum_rel = []

    for d in D_run # For each day in the test set
        t_end = t_start + t_per_d - 1
        obj_d, ps_d, ec_d, ed_d, sw_d, ls_d, λ_d = mc_storage_final(t_start, nb_t, ps_start, ps_final)
        if d == 1
            sw_cum_d = sum(sw_d[1:24]) # Add social welfare of the first day
        else
            sw_cum_d = sw_cum[end] + sum(sw_d[1:24]) # Add social welfare of the first day
        end
        sw_cum = append!(sw_cum, sw_cum_d)
        if h == nb_d_max
            sw_cum_max = sw_cum
        end
        end_of_d = ps_d["S1","T$t_end"]
        t_start += t_per_d
        ps_start = [end_of_d]
    end

    for d in D_run
        sw_cum_rel = append!(sw_cum_rel, (sw_cum_max[d]-sw_cum[d]))
    end

    if h == nb_d_max
        plot(D_str, sw_cum_rel, label="SW difference - $h days", xticks = :all, legend = false)
    else
        plot!(D_str, sw_cum_rel, label="SW difference - $h days")
    end

    sw_vs_horizon = append!(sw_vs_horizon, sw_cum_rel[end])

    nb_t -= t_per_d # Increment running horizon by 24 hours / 1 day

end

savefig("SW Difference")

plot(D_horizon_str, sw_vs_horizon, xticks = :all, legend = false)
savefig("SW Difference vs horizon")
