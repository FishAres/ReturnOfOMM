using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots

include(srcdir("utils/utils.jl"))


## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)

## ====
win_pre, win_post = 15, 30
mn_sub = 8:12 # mean subtraction pre- window
mn_window = 20:25 # window in which mean response is calculated
selectivity_threshold = 1 / 3 # => 2x larger response
act_thresh = 0.01 # activity threshold for valid selectivity index

function plot_mean_grat_act(grat_acts, cellinds; title=nothing)
    gratings = ["A1", "B3", "A3", "B4"]
    mn_std(x) = (nanmean(x, dims=2)[:], nanstd(x, dims=2)[:])
    p = plot()
    for i in 1:4 # todo why is there a 'y5'?
        mn, sd = mn_std(squeeze(nanmean(grat_acts[cellinds, i, :, :], dims=1)))
        plot!(p, mn, ribbon=sd / sqrt(length(sd)), fillalpha=0.4, label=gratings[i])
    end
    vline!([win_pre + 1])
    xticks!(1:15:45, string.(-1:1:2))
    xlabel!("Time [s]")
    ylabel!("% ΔF/F")
    title !== nothing && title!(title)
    p
end

function plot_a_b_cells(grat_acts, a_cells, b_cells)
    pa = plot_mean_grat_act(grat_acts, a_cells; title="A cells")
    ylims!(-0.03, 0.08)
    pb = plot_mean_grat_act(grat_acts, b_cells; title="B cells")
    ylims!(-0.03, 0.08)
    plot(pa, pb)
end

begin
    p = []
    for condition in 1:4
        grat_acts = pool_grat_acts(act_dict, condition; mn_sub=4:12)
        si = get_selectivity_index(grat_acts; thresh=act_thresh, mn_window=mn_window)
        a_cells = findall(>(1 / 3), si)
        b_cells = findall(<(-1 / 3), si)

        push!(p, plot_a_b_cells(grat_acts, a_cells, b_cells))

    end
    plot(p..., layout=(4, 1), size=(600, 1200))

end
