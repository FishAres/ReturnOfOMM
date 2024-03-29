

function get_act_condition(r, condition)
    as = r["act"][r["Condition"].==Float64(condition)]
    # m = trunc(Int, length(as) / 4) # all rd data are 4 x something
    reduce(hcat, [reduce(vcat, a) for a in eachcol(reshape(as, 4, :))])
end

function get_aux_condition(r, aux::String, condition)
    s = r[aux][1, :][r["Condition"][1, :].==Float64(condition)] # consider only first piezo row
    filter!(!isempty, s)
    if length(s) == 0
        return
    end
    reduce(hcat, s)[:]
end

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

inds_to_keep(x) = length(x) > 1 ? argmax(x) : 1

function clean_grat_inds(f_inds_to_keep, trav_grat_onsets, trav_grat_offsets, xpos; loc_d=0.4)
    grat_locs = collect(0.25:1.0:5) # spatial location of gratings
    clean_inds = []
    for (i, gont) in enumerate(trav_grat_onsets)
        x = xpos[gont] # x position at each grating onset
        if !isempty(x)
            grat_len = trav_grat_offsets[i] .- gont
            grats_per_pos = [gont[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
            grat_dur_per_pos = [grat_len[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
            push!(clean_inds, map((x, y) -> isempty(x) ? [] : x[f_inds_to_keep(y)], grats_per_pos, grat_dur_per_pos))
        end

    end
    return clean_inds
end

function get_clean_grat_inds(act_dict, animal, condition, f_inds_to_keep::Function=inds_to_keep)
    gratings = act_dict[animal][condition]["GratFlash"]
    xpos = act_dict[animal][condition]["VRx"]

    g_on = findall(>(1), diff(gratings)) .+ 1
    g_off = findall(<(-1), diff(gratings)) .+ 1
    xt_inds = [1; findall(<(-1), diff(xpos)) .+ 1]

    trav_grat_onsets = [g_on[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_on)] for i in eachindex(xt_inds[1:end-1])]
    trav_grat_offsets = [g_off[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_off)] for i in eachindex(xt_inds[1:end-1])]


    clean_inds = clean_grat_inds(f_inds_to_keep, trav_grat_onsets, trav_grat_offsets, xpos; loc_d=0.4)

    return clean_inds
end