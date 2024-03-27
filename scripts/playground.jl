using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using MAT

include(srcdir("utils/utils.jl"))

data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

readdir(data_dir)

proj_meta = matread(data_dir * "/OMM_1_meta.mat")["proj_meta"]

proj_meta = vars["proj_meta"]
rd = proj_meta["rd"][:]


keys(proj_meta)

animals = proj_meta["animal"][:]

proj_meta["ExpGroup"]
#=
1. Group by condition 

=#

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

unique(r["Condition"])

function get_act_dict(proj_meta)
    rd = proj_meta["rd"][:]
    act_dict = Dict()
    for animal in eachindex(rd)
        r = rd[animal]
        rdict = Dict()
        for condition in unique(r["Condition"])
            rdict[Int(condition)] = Dict()
            rdict[condition]["act"] = get_act_condition(r, condition)
            for key in aux_keys
                rdict[condition][key] = get_aux_condition(r, key, condition)
            end
        end
        act_dict[animal] = rdict
    end
    return act_dict
end

@time act_dict = get_act_dict(proj_meta)

act_dict[4][11]["act"] |> heatmap




animal_id = 1
plot([heatmap(rd[animal_id]["act_map"][i, 2], title=i, axis=nothing, colorbar=false) for i in 1:4]..., size=(1000, 1000))



@time begin
    animal_id = 5
    tp = 1
    win_pre, win_post = 30, 75
    act = rd[animal_id]["act"]
    acts = vcat([act[i, tp] for i in 1:4]...)
    grat_flash = rd[animal_id]["GratFlash"][1, tp][:]

    grat_onsets = findall(x -> x .>= 1, diff(grat_flash)) .+ 1
    grat_offsets = findall(x -> x .<= -1, diff(grat_flash)) .+ 1

    grat = filter(!isempty, [
        begin
            try
                acts[:, onset-win_pre+1:onset+win_post]
            catch
                []
            end
        end
        for onset in grat_onsets
    ])
    grat = stack(grat, dims=3)
    grat_mn = grat .- mean(grat[:, 1:3, :], dims=2)
    plot(dropdims(mean(grat, dims=3), dims=3)', legend=false)
    vline!([31])
end

ind = 0
n = size(grat, 1)
begin
    ind += 1
    p1 = plot(grat[ind, :, :], legend=false, xticks=(1:15:105, -2:1:6))
    vline!([30])
    vline!([31.5])
    title!("$ind / $n")
    p2 = heatmap(grat[ind, :, end:-1:1]', legend=false, xticks=(1:15:105, -2:1:6))
    plot(p1, p2)
end


