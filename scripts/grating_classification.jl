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

# @time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)

## ====


function classify_conds(; mn_start_inds=16:2:22, mn_win_length=5, frac_train=0.85, win_pre=15, win_post=30, mn_sub=5:10, conditions=1:4)
    cm_dict = nested_default_dict() # dict of confusion matrices
    cm_flip_dict = nested_default_dict() # as above but for flip traversals
    for condition in conditions
        for mn_start in mn_start_inds
            for animal in 1:9
                if haskey(act_dict[animal], condition)
                    grating_acts, flip_acts = get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post)

                    grat_data, targs = get_grat_data(grating_acts; mn_sub=mn_sub, mn_window=mn_start:mn_start+mn_win_length)

                    train_data, test_data = split_clean_data(grat_data, targs; frac_train=frac_train)

                    println("Training on condition $(condition), animal $(animal), mn_start $(mn_start)")
                    @time ŷ, y_test, mach = classify_grat_svm(train_data, test_data)
                    cm = confusion_matrix(ŷ, y_test).mat
                    cm_dict[condition][mn_start][animal] = cm

                    if condition in [2, 4, 5] && size(flip_acts)[end] > 0
                        cm_flip = get_flip_conf_matrix(mach, flip_acts, mn_start, mn_win_length)
                        cm_flip_dict[condition][mn_start][animal] = cm_flip
                    end
                end
            end
        end
    end
    return cm_dict, cm_flip_dict
end

"Get a dictionary of normalized confusion matrices"
function get_mean_cms(cm_dict, mn_start_inds; conditions=1:4)
    mn_dict = Dict()
    for condition in conditions
        mn_dict[condition] = []
        for mn_start in mn_start_inds
            cms = collect(values(cm_dict[condition][mn_start]))
            cms_n = map(x -> x ./ sum(x, dims=2), cms)
            push!(mn_dict[condition], cms_n)
        end
    end
    return mn_dict
end

function plot_accs(mn_dict, win_index; conditions=1:4, kwargs...)
    acc_array = [mn_dict[cond][win_index] for cond in conditions]
    accs = hcat([pad_array(mean.(diag.(acc)), (9, 1)) for acc in acc_array]...)

    plot(nanmean(accs, dims=1)[:], ribbon=sem(accs, dims=1), ylims=(0.2, 0.8); kwargs...)
    xlabel!("Condition")
    ylabel!("Accuracy")
end

function plot_accs!(mn_dict, win_index; conditions=1:4, kwargs...)
    acc_array = filter(!isempty, [mn_dict[cond][win_index] for cond in conditions])
    accs = hcat([pad_array(mean.(diag.(acc)), (9, 1)) for acc in acc_array]...)

    plot!(nanmean(accs, dims=1)[:], ribbon=sem(accs, dims=1), ylims=(0.2, 0.8); kwargs...)
    xlabel!("Condition")
    # ylabel!("Accuracy")
end


## =====
using Suppressor
mn_start_inds = 6:3:30
mn_sub = 1:5
length(mn_start_inds)
conditions = 1:4

cm_dict, cm_flip_dict = @suppress_err begin # suppress MLJ type warnings
    classify_conds(mn_start_inds=mn_start_inds, win_pre=15, win_post=30, mn_sub=mn_sub,
        conditions=conditions)
end


"Time in seconds pre/post onset"
ind_in_secs(k; win_pre=15) = round((mn_start_inds[k] - win_pre) / 15, digits=3)
mn_dict = get_mean_cms(cm_dict, mn_start_inds, conditions=conditions)

begin
    plot([plot_accs(mn_dict, k, conditions=conditions; title="$(win_in_secs(k)) s", legend=false,
        ) for k in eachindex(mn_start_inds)]..., size=(600, 600))
end

savefig("plots/grating_classification_wins.png")