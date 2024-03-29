"""
Utils for grating onsets
"""

using PaddedViews
using NaNStatistics

"""
Remove duplicate grating onsets by keeping first
"""
function clean_grating_onsets(gratings, xpos)
    grat_onsets = findall(>(1), diff(gratings)) .+ 1
    grat_id = ceil.(xpos[grat_onsets])
    # duplicate grating onsets - keep first
    dup_inds = findall(==(0), diff(grat_id))

    deleteat!(grat_onsets, dup_inds)
    deleteat!(grat_id, dup_inds)

    return grat_onsets
end


function gratings_per_trav(grat_onsets, trav_inds)
    grt_onsets = fill(NaN, (length(trav_inds) - 1, 5))
    for i in 1:length(trav_inds)-1
        trav_grat_onsets = intersect(grat_onsets, trav_inds[i]:trav_inds[i+1])
        for gr in eachindex(trav_grat_onsets)
            grt_onsets[i, gr] = trav_grat_onsets[gr]
        end
    end
    return map(x -> isnan(x) ? x : Int(x), grt_onsets)
end
