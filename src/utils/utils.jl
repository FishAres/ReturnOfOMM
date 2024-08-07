```
Utility functions for OMM data bundling and cleaning
```

using DrWatson
using MAT

include(srcdir("utils", "grating_utils.jl"))
include(srcdir("utils", "act_utils.jl"))
include(srcdir("utils", "selectivity_utils.jl"))



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


function get_act_dict(proj_meta, aux_keys)
    rd = proj_meta["rd"][:]
    proj_meta["Acode"][1] == 1 && (rd[3]["Condition"][:, 4] .= 2) # was noted in original Matlab code
    act_dict = Dict()
    for animal in eachindex(rd)
        r = rd[animal]
        rdict = Dict()
        for condition in unique(r["Condition"])
            rdict[Int(condition)] = Dict()
            rdict[condition]["act"] = get_act_condition(r, condition)
            for key in aux_keys
                if haskey(r, key)
                    rdict[condition][key] = get_aux_condition(r, key, condition)
                end
            end
        end
        act_dict[animal] = rdict
    end
    return act_dict
end


## ==== WIP: more ways of cleaning up grating onsets

inds_to_keep(x) = length(x) > 1 ? argmax(x) : 1

function clean_grat_inds(f_inds_to_keep, trav_grat_onsets, trav_grat_offsets, xpos; loc_d=0.4)
    grat_locs = collect(0.25:1.0:5) # spatial location of gratings
    clean_inds = []
    for (i, gont) in enumerate(trav_grat_onsets)
        x = xpos[gont] # x position at each grating onset
        # if !isempty(x)
        if length(gont) > 4
            grat_len = trav_grat_offsets[i] .- gont

            try
                @assert minimum(grat_len) > 0 # make sure there's no negatives heah                
            catch
                println(grat_len)
            end

            grats_per_pos = [gont[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
            grat_dur_per_pos = [grat_len[gl-loc_d.<=x.<=gl+loc_d] for gl in grat_locs]
            push!(clean_inds, map((x, y) -> isempty(x) ? [] : x[f_inds_to_keep(y)], grats_per_pos, grat_dur_per_pos))
        end

    end
    return clean_inds
end

```
Pad grating offsets with index of final position when traversal ends before a grating offset
```
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


function get_clean_grat_inds(gratings::AbstractArray, xpos::AbstractArray, f_inds_to_keep::Function=inds_to_keep)

    g_on = findall(>(1), diff(gratings)) .+ 1
    g_off = findall(<(-1), diff(gratings)) .+ 1
    xt_inds = [1; findall(<(-1), diff(xpos)) .+ 1]

    trav_grat_onsets = [g_on[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_on)] for i in eachindex(xt_inds[1:end-1])]
    trav_grat_offsets = [g_off[findall(x -> xt_inds[i] < x < xt_inds[i+1], g_off)] for i in eachindex(xt_inds[1:end-1])]

    trav_grat_onsets, trav_grat_offsets = pad_grat_ons_offs(trav_grat_onsets, trav_grat_offsets)

    clean_inds = clean_grat_inds(f_inds_to_keep, trav_grat_onsets, trav_grat_offsets, xpos; loc_d=0.4)

    return clean_inds
end


function get_clean_grat_inds(act_dict::Dict, animal::Int, condition::Number, f_inds_to_keep::Function=inds_to_keep)
    gratings = act_dict[animal][condition]["GratFlash"]
    xpos = act_dict[animal][condition]["VRx"]
    return get_clean_grat_inds(gratings, xpos, f_inds_to_keep)
end

## ==== 
using DataStructures

"tricky dict to avoid having to create nested dicts in a loop"
function nested_default_dict()
    return DefaultDict{Any,Any}(nested_default_dict)
end

"""
Recursively turn keys of a nested dictionary into strings
"""
function keys_to_string(dict)
    new_dict = Dict()
    for (k, v) in dict
        k_str = string(k)
        if v isa Dict || v isa DefaultDict
            new_dict[k_str] = keys_to_string(v)
        else
            new_dict[k_str] = v
        end
    end
    return new_dict
end


# = Stuff to deal with NaNs

function nanfunc(f, x; dims=1)
    nanop = mapslices(x -> f(x[.!isnan.(x)]), x, dims=dims)
    return nanop
end

nanmean(x; dims=1) = nanfunc(mean, x; dims=dims)
nanstd(x; dims=1) = nanfunc(std, x; dims=dims)

"standard error of the mean"
function sem(x; dims=2)
    std = nanstd(x, dims=dims)
    return std ./ sqrt.(size(x, dims))
end

non_nan_rows(x) = findall(z -> !any(isnan, z), eachrow(x))

function filter_nan_col(x)
    x[:, [!any(isnan.(col)) for col in eachcol(x)]]
end

function filter_nan_row(x)
    x[[!any(isnan.(row)) for row in eachrow(x)], :]
end
