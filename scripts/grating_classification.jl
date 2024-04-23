using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using JLD2
include(srcdir("utils/utils.jl"))

## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = JLD2.load(datadir("exp_pro", "OMM3_act_dict.jld2"))["act_dict"]


## ====

mn_start_inds = 16:2:22
mn_sub = 5:10
cm_dict, cm_flip_dict = run_allcond_classification(act_dict, mn_start_inds, mn_sub; conditions=1:4)

plot_class_results(mn_start_inds, cm_dict)

