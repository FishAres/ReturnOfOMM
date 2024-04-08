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
mn_sub = 5:10

using MLJ

function classify_gratings(animal, condition; mn_sub=5:10, mn_window=16:20)
    grating_acts, flip_acts = get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post)

    grating_acts_mnsub = mean_subtract(grating_acts, mn_sub, dims=3)
    ga_mn = squeeze(nanmean(grating_acts_mnsub[:, :, mn_window, :], dims=3))

    grat_resps = reshape(ga_mn, size(ga_mn, 1), :)
    targs = repeat(1:5, 1, size(ga_mn)[end])[:]

    (X_train, X_test), (y_train, y_test) = partition((grat_resps', targs), 0.85, multi=true, shuffle=true)

    modelType = @load RandomForestClassifier pkg = "BetaML" verbosity = 0
    model = modelType()
    mach = machine(model, X_train, categorical(y_train))
    fit!(mach)

    ŷ = Vector{Int64}(mode.(predict(mach, X_test))) # why are these types so weird
    return mach, ŷ, y_test
end


begin
    cm_dict = Dict()
    for mn_start in [11, 16, 20]
        cm_dict[mn_start] = Dict()
        for animal in 4:9
            @info "Training on animal $(animal), mn_start $(mn_start)"
            @time mach, ŷ, y_test = classify_gratings(animal, 4; mn_window=mn_start:mn_start+5)
            cm = confusion_matrix(ŷ, y_test).mat
            cm_dict[mn_start][animal] = cm
        end
    end
end

## ====

begin
    ps = []
    for (i, mn_start) in enumerate([11, 16, 20])
        cms = collect(values(cm_dict[mn_start]))
        cms_n = map(x -> x ./ sum(x, dims=2), cms) |> mean
        # heatmap!(cms_n)
        push!(ps, heatmap(cms_n, clim=(0, 1), title=mn_start))
    end
end

plot(ps..., layout=(3, 1), size=(500, 1500))



plot(squeeze(nanmean(flip_acts[a_cells, 5, :, :], dims=3))', legend=false)
vline!([15], label=nothing, color=:black)
plot(squeeze(nanmean(flip_acts[b_cells, 5, :, :], dims=3))', legend=false)
vline!([15], label=nothing, color=:black)


heatmap(flip_acts[b_cells[103], 5, :, :]')




begin
    animal, condition = 6, 4
    gratings = act_dict[animal][condition]["GratFlash"]
    xpos = act_dict[animal][condition]["VRx"]
    act = act_dict[animal][condition]["act"]
    trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]
    grat_onsets = clean_grating_onsets(gratings, xpos)
    flips = act_dict[animal][condition]["Flip"]
    flip_onsets = findall(>(1), diff(flips)) .+ 1

    i = [intersect(flip_onsets, trav_inds[i]:trav_inds[i+1]) for i in 1:length(trav_inds)-1]
    flip_trav_inds = findall(!isempty, i)

    grat_acts = mean_subtract(get_cond_grat_act(act_dict, animal, condition), 5:14, dims=3)
    @time si = get_selectivity_index(grat_acts)
    si_thresh = 1 / 3
    a_cells = findall(>(si_thresh), si)
    b_cells = findall(<(si_thresh), si)

    flip_acts = grat_acts[:, :, :, flip_trav_inds]
    g_acts = grat_acts[:, :, :, setdiff(1:size(grat_acts, 4), flip_trav_inds)]

    p2 = plot(
        [plot_onset_means(grat_acts, flip_acts, cellinds) for cellinds in [a_cells, b_cells]]...)

    p2
end

function plot_onset_means(grat_acts, flip_acts, cellinds)
    gratings = condition > 2 ? ["A1", "B3", "A3", "B4", "B5"] : ["A1", "B3", "A3", "B4", "A5"]
    mn_std(x) = (nanmean(x, dims=2)[:], nanstd(x, dims=2)[:])
    p = plot()
    for i in 1:5
        mn, sd = mn_std(squeeze(nanmean(grat_acts[cellinds, i, :, :], dims=1)))
        plot!(p, mn, ribbon=sd / sqrt(length(sd)), fillalpha=0.3,
            linewidth=2, label=gratings[i])
    end
    mn, sd = mn_std(squeeze(nanmean(flip_acts[cellinds, 5, :, :], dims=1)))
    plot!(p, mn, ribbon=sd / sqrt(length(sd)), fillalpha=0.3, linewidth=2, label=condition > 2 ? "A5" : "B5")
    vline!([win_pre + 1], color=:black, label=nothing)
    xticks!(1:15:45, string.(-1:1:2))
    xlabel!("Time [s]")
    ylabel!("% ΔF/F")
    p
end
plot_onset_means(grat_acts, flip_acts, a_cells)


function plot_a_b_cells(grat_acts, a_cells, b_cells)
    pa = plot_mean_grat_act(grat_acts, a_cells; title="A cells")
    ylims!(-0.03, 0.08)
    pb = plot_mean_grat_act(grat_acts, b_cells; title="B cells")
    ylims!(-0.03, 0.08)
    plot(pa, pb)
end


