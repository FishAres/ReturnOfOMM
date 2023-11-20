using DrWatson
using LinearAlgebra, Statistics
using Plots
using MAT

vars = matread(datadir("exp_pro", "OMM_1_meta.mat"))
proj_meta = vars["proj_meta"]
rd = proj_meta["rd"][:]


animal_id = 1
plot([heatmap(rd[animal_id]["act_map"][i, 2], title=i, axis=nothing, colorbar=false) for i in 1:4]..., size=(1000, 1000))

@time begin
    animal_id = 9
    tp = 11
    win_pre, win_post = 10, 21
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
    grat = grat .- mean(grat[:, 1:3, :], dims=2)
    plot(dropdims(mean(grat, dims=3), dims=3)', legend=false)
    vline!([10])
end

grat

heatmap(dropdims(mean(grat, dims=3), dims=3), legend=false)
vline!([10])
heatmap(grat)