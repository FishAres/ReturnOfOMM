

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