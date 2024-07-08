using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots

include(srcdir("utils/utils.jl"))

## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

# proj_meta = matread(data_dir * "/ARW_20new.mat")["proj_meta"]
# proj_meta["rd"][23]["timepoint"][:][1]

# @time act_dict = get_act_dict(matread(data_dir * "/OMM3.mat")["proj_meta"], aux_keys)
using JLD2
@time act_dict = JLD2.load(datadir("exp_pro", "OMM1_act_dict.jld2"))["act_dict"]

## ======

animal, condition = 4, 4

gratings = act_dict[animal][condition]["GratFlash"]
xpos = act_dict[animal][condition]["VRx"]
trav_inds = [1; findall(<(-0.4), diff(xpos)) .+ 1; length(xpos)]
grat_onsets = clean_grating_onsets(gratings, xpos)
act = act_dict[animal][condition]["act"]

velp = act_dict[animal][condition]["velP_smoothed"]

begin
    act_per_trav, vel_per_trav = [], []
    for i in eachindex(trav_inds[2:end-1])
        push!(vel_per_trav, velp[trav_inds[i]:trav_inds[i+1]])
        push!(act_per_trav, act[:, trav_inds[i]:trav_inds[i+1]])
    end
end

act_per_trav[2]
vel_per_trav[2]

using MLJ

