using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots

include(srcdir("utils/utils.jl"))

## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

# @time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)
using JLD2

@time act_dict = JLD2.load(datadir("exp_pro", "OMM1_act_dict.jld2"))["act_dict"]
## =====
animal, condition = 5, 4

xpos = act_dict[animal][condition]["VRx"]
trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]
act = act_dict[animal][condition]["act"]

bin_size = 5 ./ 100
xt = collect(0:bin_size:5)

function get_trav_act(xpos, act, trav_inds)
    xp = [xpos[trav_inds[i]:trav_inds[i+1]-1] for i in eachindex(trav_inds[1:end-1])]
    a = [act[:, trav_inds[i]:trav_inds[i+1]-1] for i in eachindex(trav_inds[1:end-1])]
    return xp, a
end

function get_bin_inds(xp; n_bins=100)
    bin_size = 5.0 ./ n_bins
    xt = collect(0.0:bin_size:5.0)
    # sorted_xpos = sort(xp)
    sorted_xpos = xp
    bin_inds = Vector{Vector{Int}}(undef, length(xt) - 1)
    j = 1
    for i in 1:length(xt)-1
        inds = Int[]
        while j <= length(sorted_xpos) && xt[i] <= sorted_xpos[j] < xt[i+1]
            push!(inds, j)
            j += 1
        end
        bin_inds[i] = inds
    end
    return bin_inds
end

xp, a = get_trav_act(xpos, act, trav_inds)

@time bin_inds = get_bin_inds.(xp)

## =====

xpos = act_dict[animal][condition]["VRx"]
grat = act_dict[animal][condition]["GratFlash"]
trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]
act = act_dict[animal][condition]["act"]
grat_offsets = findall(<(-1), diff(grat)) .+ 1
plotlyjs()
histogram(xpos[grat_offsets], bins=0:0.1:5)


function get_binned_act(xpos, act, trav_inds)
    xp, a = get_trav_act(xpos, act, trav_inds)
    bin_inds = get_bin_inds.(xp)
    binned_acts_list = []
    for j in eachindex(a)
        push!(binned_acts_list, map(i -> nanmean(a[j][:, i], dims=2), bin_inds[j]))
    end
    return cat([reduce(hcat, x) for x in binned_acts_list]..., dims=3)
end


begin
    animal, condition = 5, 4
    xpos = act_dict[animal][condition]["VRx"]
    trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]
    act = act_dict[animal][condition]["act"]

    @time binned_acts = get_binned_act(xpos, act, trav_inds)
    flip_travs = get_flip_travs(trav_inds, act_dict[animal][condition]["Flip"])
    normal_travs = setdiff(1:size(binned_acts, 3), flip_travs)

    begin
        p1 = squeeze(nanmean(binned_acts[:, :, normal_travs], dims=3)) |> heatmap
        p2 = squeeze(nanmean(binned_acts[:, :, flip_travs], dims=3)) |> heatmap
        p = plot(p1, p2, layout=(2, 1), size=(400, 600))
    end
    p
end

cellind = 0
ncells = size(binned_acts, 1)
gpos = (0:4) .+ 0.35
goff_pos = (0:4) .+ 0.65
begin
    cellind += 1
    plot(squeeze(nanmean(binned_acts[cellind, :, normal_travs], dims=2)), legend=false)
    plot!(squeeze(nanmean(binned_acts[cellind, :, flip_travs], dims=2)), legend=false)
    vline!([gpos .* 20], color=:black)
    vline!([goff_pos .* 20], color=:grey)
    title!("$(cellind) / $(ncells)")
end

