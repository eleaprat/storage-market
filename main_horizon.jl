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

nb_g = div((ncol(G_df)-1),3)
nb_l = div((ncol(L_df)-1),3)
nb_w = div((ncol(W_df)-1),3)
nb_s = nrow(S_df)
nb_t_tot = nrow(G_df)
#nb_d = div(nb_t_tot,24)
nb_d = 30
∆t = 1 # Time steps of 1 hour
t_per_d = div(24,∆t)

## Create Sets

G = ["G$i" for i in 1:nb_g]

L = ["L$i" for i in 1:nb_l]

W = ["W$i" for i in 1:nb_w]

S = ["S$i" for i in 1:nb_s]

T_tot = ["T$i" for i in 0:nb_t_tot]

T_d = ["T$i" for i in 0:24]

D = [i for i in 1:nb_d]

D_str = ["$i" for i in 1:nb_d]

include("final_level_fct.jl")

# Initialization
nb_t = 0
ps_end_d1 = []
ps_end_d2 = []

ps_init = []
ps_final = []
for s in nb_s
    global ps_init, ps_final
    ps_init = append!(ps_init, S_df[s, "SOC Init"])
    ps_final = append!(ps_final, S_df[s, "SOC End"])
end

for d in D
    global nb_t, ps_end_d1, ps_end_d2
    nb_t += t_per_d

    # Day 1
    t_start = 1
    obj_d1, ps_d1, ec_d1, ed_d1, sw_d1, ls_d1, λ_d1 = mc_storage_final(t_start, nb_t, ps_init, ps_final)
    end_of_d1 = ps_d1["S1","T24"]
    print("End of day 1: $end_of_d1",)
    ps_end_d1 = append!(ps_end_d1, end_of_d1)

    # Day 2
    t_start = 1 + t_per_d
    obj_d2, ps_d2, ec_d2, ed_d2, sw_d2, ls_d2, λ_d2 = mc_storage_final(t_start, nb_t, [end_of_d1], ps_final)
    end_of_d2 = ps_d2["S1","T48"]
    print("End of day 2: $end_of_d2",)
    ps_end_d2 = append!(ps_end_d2, end_of_d2)
end

plot(D_str, ps_end_d1, legend = false, xticks = :all)
savefig("Final Level Day 1")

plot(D_str, ps_end_d2, legend = false, xticks = :all)
savefig("Final Level Day 2")
