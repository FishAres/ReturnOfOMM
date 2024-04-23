using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using JLD2
include(srcdir("utils/utils.jl"))

## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = JLD2.load(datadir("exp_pro", "OMM1_act_dict.jld2"))["act_dict"]
## =====

# functions 
include(srcdir("utils", "predictive_visual_cell_utils.jl"))

win_pre, win_post = 15, 30
mn_sub = 5:10

function get_condition_pred_vis_cor(act_dict, condition; mn_sub=5:10, sel_thresh=0.33, mn_act_win=16:20)
    pv_cors = []
    for animal in 1:length(act_dict)
        if haskey(act_dict[animal], condition)
            try
                grat_act, flip_act = map(x -> mean_subtract(x, mn_sub, dims=3), get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post))

                push!(pv_cors, get_pred_vis_cor(grat_act, flip_act, condition; sel_thresh=sel_thresh, mn_act_win=mn_act_win))
            catch
                continue
                # @info "Animal $animal in condition $condition either has no predictive or no visual cells based on the criteria"
            end
        end
    end
    return pv_cors
end

for condition in [2, 4, 5]
    pv_cors = get_condition_pred_vis_cor(act_dict, condition)
    filter!(x -> !(all(isnan.(x))), pv_cors)
    mean_cor = mean(mean.(pv_cors))
    println("Cond $condition predictive-visual cell correlation is $(round(mean_cor, digits=3))")
end
