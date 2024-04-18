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

win_pre, win_post = 15, 30
mn_sub = 5:10

using MLJ


function classify_conds(; mn_start_inds=16:2:22, mn_win_length=5, frac_train=0.85, win_pre=15, win_post=30, mn_sub=5:10)
    cm_dict = nested_default_dict() # dict of confusion matrices
    cm_flip_dict = nested_default_dict() # as above but for flip traversals
    for condition in 1:5
        for mn_start in mn_start_inds
            for animal in 1:9
                if haskey(act_dict[animal], condition)
                    grating_acts, flip_acts = get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post)

                    grat_data, targs = get_grat_data(grating_acts; mn_sub=mn_sub, mn_window=mn_start:mn_start+mn_win_length)

                    train_data, test_data = split_clean_data(grat_data, targs; frac_train=frac_train)

                    @info "Training on condition $(condition), animal $(animal), mn_start $(mn_start)"
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

function get_mean_cms(cm_dict, mn_start_inds)
    mn_dict = Dict()
    for condition in 1:4
        mn_dict[condition] = []
        for mn_start in mn_start_inds
            cms = collect(values(cm_dict[condition][mn_start]))
            cms_n = map(x -> x ./ sum(x, dims=2), cms)
            push!(mn_dict[condition], cms_n)
        end
    end
    return mn_dict
end

function plot_accs(mn_dict, mn_start_inds, win_index; conditions=1:4)
    acc_array = [mn_dict[cond][win_index] for cond in conditions]
    accs = hcat([pad_array(mean.(diag.(acc)), (9, 1)) for acc in acc_array]...)

    plot(nanmean(accs, dims=1)[:], ribbon=sem(accs, dims=1), legend=false, ylims=(0.2, 0.8))
    xlabel!("Condition")
    ylabel!("Accuracy")
    title!("Window $(mn_start_inds[win_index])")
end


mn_start_inds = 6:2:26
cm_dict, cm_flip_dict = classify_conds(mn_start_inds=mn_start_inds)


mn_dict = get_mean_cms(cm_dict, mn_start_inds)
plot([plot_accs(mn_dict, mn_start_inds, k) for k in eachindex(mn_start_inds)]...)

cm_flip_dict[5]


## ====

begin
    ps = []
    for condition in 1:4
        for (i, mn_start) in enumerate(11:2:20)
            cms = collect(values(cm_dict[condition][mn_start]))
            cms_n = map(x -> x ./ sum(x, dims=2), cms)
            cms_n = squeeze(nanmean(cat(cms_n..., dims=3), dims=3))
            push!(ps, heatmap(cms_n, clim=(0, 1), title="$(mn_start), $(condition)", colorbar=false))
        end
    end
end



