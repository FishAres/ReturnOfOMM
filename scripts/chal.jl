using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using MAT

include(srcdir("utils/utils.jl"))

data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

readdir(data_dir)

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = get_act_dict(proj_meta)

begin
    condition = 4
    act_dict[4][condition]["act"]
    g = act_dict[4][condition]["GratFlash"]
    rw = act_dict[4][condition]["Reward"]
    xpos = act_dict[4][condition]["VRx"]

    g_inds = findall(>(1), diff(g)) .+ 1
    rw_inds = findall(>(1), diff(rw)) .+ 1
end

g_inds
rw_inds

rwi = [1; rw_inds]

gw = [g[rwi[i]:rwi[i+1]] for i in eachindex(rwi[1:end-1])]
xp = [xpos[rwi[i]:rwi[i+1]] for i in eachindex(rwi[1:end-1])]

go = map(x -> findall(>(1), diff(x)), gw)
gb = findall(>(5), length.(go))

plot(gw[gb[1]])
plot!(xp[gb[1]])

argmin(diff(rw_inds))
minimum(diff(rw_inds))

rw_inds[61]
rw_inds[62]

plot(rw[rw_inds[60]:rw_inds[62]])
vline!(rw_inds[61])

histogram(diff(rwi))












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


