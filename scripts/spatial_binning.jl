using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots

include(srcdir("utils/utils.jl"))

## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)
