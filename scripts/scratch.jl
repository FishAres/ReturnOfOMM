using DrWatson
@quickactivate "OMM"
using LinearAlgebra, Statistics
using Plots
using MAT

plotlyjs()

include(srcdir("utils/utils.jl"))
## ====
data_dir = "C:/Users/aresf/Desktop/OMM_archive_submission_final/OMM_archive_submission_final/data"

aux_keys = ["blink", "GratFlash", "Licking", "pupil_diam", "Flip", "Reward", "velP_smoothed", "airPuff", "VRx", "pupil_pos"]

@time act_dict = get_act_dict(matread(data_dir * "/OMM_1_meta.mat")["proj_meta"], aux_keys)

## ====
act_dict[1][1]

for animal in 1:9
    for condition in keys(act_dict[animal])
        try
            clean_inds = reduce(vcat, get_clean_grat_inds(act_dict, animal, condition))
            act_dict[animal][condition]["grat_onsets"] = clean_inds
        catch e
            println(animal, " ", condition)
            println(e)
        end
    end
end



function check_ons_offs_len(animal, condition)
    gratings = act_dict[animal][condition]["GratFlash"]
    xpos = act_dict[animal][condition]["VRx"]

    g_on = findall(>(1), diff(gratings)) .+ 1
    g_off = findall(<(-1), diff(gratings)) .+ 1
    xt_inds = [1; findall(<(-1), diff(xpos)) .+ 1]

    trav_grat_onsets = [g_on[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_on)] for i in eachindex(xt_inds[1:end-1])]
    trav_grat_offsets = [g_off[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_off)] for i in eachindex(xt_inds[1:end-1])]

    uneq_inds = findall(==(1), [length(a) != length(b) for (a, b) in zip(trav_grat_onsets, trav_grat_offsets)])

    return trav_grat_onsets[uneq_inds], trav_grat_offsets[uneq_inds]
end

animal, condition = 6, 3
gratings = act_dict[animal][condition]["GratFlash"]
xpos = act_dict[animal][condition]["VRx"]

g_on = findall(>(1), diff(gratings)) .+ 1
g_off = findall(<(-1), diff(gratings)) .+ 1
xt_inds = [1; findall(<(-1), diff(xpos)) .+ 1]

trav_grat_onsets = [g_on[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_on)] for i in eachindex(xt_inds[1:end-1])]
trav_grat_offsets = [g_off[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_off)] for i in eachindex(xt_inds[1:end-1])]
xts = [xpos[xt_inds[i]:xt_inds[i+1]] for i in eachindex(xt_inds[1:end-1])]


function pad_grat_ons_offs(trav_grat_onsets, trav_grat_offsets)
    for (i, (t_on, t_off)) in enumerate(zip(trav_grat_onsets, trav_grat_offsets))
        if length(t_on) > length(t_off)
            push!(trav_grat_offsets[i], xt_inds[i+1])
        elseif length(t_off) > length(t_on)
            trav_grat_offsets[i] = trav_grat_offsets[i][2:end]
        end
    end
    return trav_grat_onsets, trav_grat_offsets
end





begin
    for animal in 1:9
        for condition in keys(act_dict[animal])
            ons, offs = check_ons_offs_len(animal, condition)
            for (i, (on, off)) in enumerate(zip(ons, offs))
                if length(on) > length(off)
                    println("animal $(animal), cond $(condition), $(i) ons longer")
                elseif length(off) > length(on)
                    println("animal $(animal), cond $(condition), $(i) ons shorter")
                end
            end
        end
    end
end


ons, offs = check_ons_offs_len(5, 1)

ons[1]
offs[1]

plot(ons[2])
plot!(offs[2][2:end])


i = 20
gont = trav_grat_onsets[i]
grat_len = trav_grat_offsets[i] .- gont
x = xpos[gont]

grats_per_pos = [gont[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
grat_dur_per_pos = [grat_len[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
map((x, y) -> x[inds_to_keep(y)], grats_per_pos, grat_dur_per_pos)

mean(length.(clean_inds))

scatter(x, grat_len)


# tmp = [(b .- a) for (a, b) in zip(grat_on_trav, grat_off_trav)]






## ====




findall(x -> length(x) > 5, grat_per_trav)

plot(trav_xpos[9])
plot!(gw[9])

grat_on_trav[9]
grat_off_trav[9]

grat_durations = map((a, b) -> a - b, grat_off_trav, grat_on_trav)

grat_on_trav[9]


xp = [xpos[xt[i]:xt[i+1]] for i in eachindex(xt[1:end-1])]
go = map(x -> findall(>(1), diff(x)), gw)



histogram(diff(xt_inds))
histogram!(diff(rw_inds), alpha=0.5)
minimum(diff(xt_inds))
mean(diff(xt_inds)) / 15

rwi = [1; rw_inds]

gw = [g[rwi[i]:rwi[i+1]] for i in eachindex(rwi[1:end-1])]
xp = [xpos[rwi[i]:rwi[i+1]] for i in eachindex(rwi[1:end-1])]

go = map(x -> findall(>(1), diff(x)), gw)
grat_duplication_inds = findall(!=(5), length.(go))

for ind in eachindex(grat_duplication_inds)
    tmp = gw[grat_duplication_inds[ind]]
    p = plot(tmp)
    plot!(xp[grat_duplication_inds[ind]])
    xticks!(1:30:length(tmp), string.(Int.(0:2:length(tmp)/15)))

    display(p)
end











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


