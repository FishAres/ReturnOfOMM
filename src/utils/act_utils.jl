"""
Utility functions for calculating activity arrays
"""

using NaNStatistics

"""
Squeeze it (similar to `np.squeeze`)
"""
function squeeze(x::AbstractArray)
    return dropdims(x, dims=tuple(findall(==(1), size(x))...))
end


"""
Subtract the mean of array x in `window` at dimension `dims`
"""
function mean_subtract(x::AbstractArray, window::UnitRange=1:5; dims=2)
    ranges = [1:size(x, dim) for dim in 1:ndims(x)]
    ranges[dims] = window
    mn = mapslices(nanmean, x[ranges...], dims=dims)

    return x .- mn
end


"""
Pad the columns of a matrix with NaNs to fill a desired dimension
(if for example a traversal ends early)
"""
function pad_column!(x::AbstractMatrix, l_des)
    m, n = size(x)
    x = n < l_des ? [x fill(NaN, m, l_des - n)] : x
end


"""
Pad array `x` with NaNs at dimensions `dims`
with the help of Copilot. Note that the number of dimensions must be equal to those of `x`
"""
function pad_array(x::AbstractArray, desired_dims)
    original_dims = size(x)
    padding_dims = desired_dims .- original_dims

    for dim in 1:length(desired_dims)
        if padding_dims[dim] > 0
            ranges = [1:original_dims[i] for i in eachindex(original_dims)]

            # Replace the range for the dimension to be padded with the padding size
            ranges[dim] = 1:padding_dims[dim]
            nan_array = fill(NaN, ranges...)
            x = cat(x, nan_array, dims=dim)
        end
    end
    return x
end


function get_grat_acts(act, grat_onsets, trav_inds)
    grats_per_trav = gratings_per_trav(grat_onsets, trav_inds)

    grat_acts = [[act[:, k-win_pre:min(k + win_post, trav_inds[end])] for k in filter(!isnan, grats_per_trav[:, g])] for g in 1:5]

    # todo replace pad_column! with pad_array
    grat_acts = [map(x -> pad_column!(x, win_pre + win_post + 1), grat_act) for grat_act in grat_acts]

    return map(x -> cat(x..., dims=3), grat_acts)
end
