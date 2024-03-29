using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using MAT
using NaNStatistics


plotlyjs()

include(srcdir("utils/utils.jl"))
include(srcdir("utils", "grating_utils.jl"))
include(srcdir("utils", "act_utils.jl"))


## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)

## ====
win_pre, win_post = 15, 15
animal, condition = 4, 4

gratings = act_dict[animal][condition]["GratFlash"]
xpos = act_dict[animal][condition]["VRx"]
trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]

grat_onsets = clean_grating_onsets(gratings, xpos)

act = act_dict[animal][condition]["act"]


grat_acts = get_grat_acts(act, grat_onsets, trav_inds)
sz = maximum(size.(grat_acts))
grat_acts = map(x -> pad_array(x, sz), grat_acts)
grat_acts = permutedims(cat(grat_acts..., dims=4), (1, 4, 2, 3))

ga_mn = mean_subtract(grat_acts, 8:12, dims=3)


begin
    p = [
        begin
            plot(squeeze(nanmean(ga_mn[:, i, :, :], dims=3))', legend=false)
            vline!([15], color=:black)
            xticks!(0:15:45, string.(-1:1:2))
        end for i in 1:5
    ]
    plot(p...)
end

## ====

for animal in 1:9
    for condition in keys(act_dict[animal])
        try
            clean_inds = reduce(vcat, get_clean_grat_inds(act_dict, animal, condition))
            act_dict[animal][condition]["grat_onsets"] = clean_inds
        catch e
            println(animal, " ", condition)
            println(e)
        end
    end
end

function pad_grat_ons_offs(trav_grat_onsets, trav_grat_offsets)
    for (i, (t_on, t_off)) in enumerate(zip(trav_grat_onsets, trav_grat_offsets))
        if length(t_on) > length(t_off)
            push!(trav_grat_offsets[i], xt_inds[i+1])
        elseif length(t_off) > length(t_on)
            trav_grat_offsets[i] = trav_grat_offsets[i][2:end]
        end
    end
    return trav_grat_onsets, trav_grat_offsets
end



for animal in 1:9
    for condition in keys(act_dict[animal])
        g_on = findall(>(1), diff(gratings)) .+ 1
        g_off = findall(<(-1), diff(gratings)) .+ 1
        xt_inds = [1; findall(<(-1), diff(xpos)) .+ 1]

        trav_grat_onsets = [g_on[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_on)] for i in eachindex(xt_inds[1:end-1])]
        trav_grat_offsets = [g_off[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_off)] for i in eachindex(xt_inds[1:end-1])]

        for (i, (t_on, t_off)) in enumerate(zip(trav_grat_onsets, trav_grat_offsets))
            if length(t_on) > length(t_off)
                push!(trav_grat_offsets[i], xt_inds[i+1])
            elseif (length(t_off) > length(t_on)) & (t_on[1] < t_off[1])
                trav_grat_offsets[i] = trav_grat_offsets[i][2:end]
            else
                println("animal $(animal) cond $(condition) $i")
            end
        end

        # for (i, (t_on, t_off)) in enumerate(zip(trav_grat_onsets, trav_grat_offsets))
        # gd = t_off - t_on
        # try
        # @assert minimum(gd) > 0
        # catch
        # println("animal $(animal) cond $(condition) $i")
        # end
        # end
    end
end





begin
    animal, condition = 3, 2
    grat_onsets = act_dict[animal][condition]["grat_onsets"]
    xpos = act_dict[animal][condition]["VRx"]

    histogram(xpos[grat_onsets])
end

act_dict[animal][condition]