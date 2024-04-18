"""
Utility functions for calculating activity arrays
"""


"""
Squeeze it (similar to `np.squeeze`)
"""
function squeeze(x::AbstractArray)
    return dropdims(x, dims=tuple(findall(==(1), size(x))...))
end


"""
Subtract the mean of array x in `window` at dimension `dims`
"""
# function mean_subtract(x::AbstractArray, window::UnitRange=1:5; dims=2)
#     ranges = [1:size(x, dim) for dim in 1:ndims(x)]
#     ranges[dims] = window
#     mn = mapslices(nanmean, x[ranges...], dims=dims)

#     return x .- mn
# end

function mean_subtract(x::AbstractArray, window::UnitRange=1:5; dims=2)
    ranges = [1:size(x, dim) for dim in 1:ndims(x)]
    ranges[dims] = window
    mn = nanmean(x[ranges...], dims=dims)
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
with the help of Copilot. Note that the *number* of dimensions must be equal to those of `x`
"""
function pad_array(x::AbstractArray, desired_dims)
    function UR_to_dims(ur)
        Tuple(i[end] for i in ur)
    end
    original_dims = size(x)
    padding_dims = desired_dims .- original_dims

    for dim in 1:length(desired_dims)
        if padding_dims[dim] > 0
            ranges = [1:original_dims[i] for i in eachindex(original_dims)]

            # Replace the range for the dimension to be padded with the padding size
            ranges[dim] = 1:padding_dims[dim]

            nan_array = fill(NaN, UR_to_dims(ranges))

            x = cat(x, nan_array, dims=dim)
        end
    end
    return x
end


function get_grat_acts(act, grat_onsets, trav_inds; win_pre=15, win_post=30)
    grats_per_trav = gratings_per_trav(grat_onsets, trav_inds)

    grat_acts = [[act[:, k-win_pre:min(k + win_post, trav_inds[end])] for k in filter(!isnan, grats_per_trav[:, g])] for g in 1:5]

    # todo replace pad_column! with pad_array
    grat_acts = [map(x -> pad_column!(x, win_pre + win_post + 1), grat_act) for grat_act in grat_acts]

    return map(x -> cat(x..., dims=3), grat_acts)
end


function get_flip_travs(trav_inds, flips)
    flip_onsets = findall(>(1), diff(flips)) .+ 1

    flip_trav_inds = findall(!isempty,
        [intersect(flip_onsets, trav_inds[i]:trav_inds[i+1]) for i in 1:length(trav_inds)-1])
    return flip_trav_inds
end

function get_cond_grat_act(act_dict, animal, condition; win_pre=15, win_post=30)
    gratings = act_dict[animal][condition]["GratFlash"]
    xpos = act_dict[animal][condition]["VRx"]
    trav_inds = [1; findall(<(-1), diff(xpos)) .+ 1; length(xpos)]
    grat_onsets = clean_grating_onsets(gratings, xpos)
    act = act_dict[animal][condition]["act"]

    flips = act_dict[animal][condition]["Flip"]
    flip_trav_inds = get_flip_travs(trav_inds, flips)
    (condition in [1, 2]) && (flip_trav_inds = [])

    grat_acts = get_grat_acts(act, grat_onsets, trav_inds; win_pre=win_pre, win_post=win_post)
    sz = maximum(size.(grat_acts)) # find largest array size to pad into
    grat_acts = map(x -> pad_array(x, sz), grat_acts) # pad to largest
    # cells x gratings x time x traversals
    grat_acts = permutedims(cat(grat_acts..., dims=4), (1, 4, 2, 3))

    filter!(<(size(grat_acts, 4)), flip_trav_inds)
    flip_acts = grat_acts[:, :, :, flip_trav_inds]
    g_acts = grat_acts[:, :, :, setdiff(1:size(grat_acts, 4), flip_trav_inds)]

    return g_acts, flip_acts

end

function pool_grat_acts(act_dict, condition; mn_sub=8:12, win_pre=15, win_post=30)
    grat_acts = [get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post) for animal in 4:9]

    g_acts = first.(grat_acts)
    flip_acts = last.(grat_acts)
    map_pad(ga) = begin
        max_trav_len = maximum(size.(ga, 4))
        ga_padded = map(x -> pad_array(x, (size(x)[1:3]..., max_trav_len)), ga)
        return vcat(ga_padded...)
    end

    return map_pad.((g_acts, flip_acts))
end

function plot_mean_grat_act(grat_acts, cellinds; title=nothing)
    gratings = ["A1", "B3", "A3", "B4"]
    p = plot()
    for i in 1:4
        mn, sd = mn_std(squeeze(nanmean(grat_acts[cellinds, i, :, :], dims=1)))
        plot!(p, mn, ribbon=sd / sqrt(length(sd)), fillalpha=0.4, label=gratings[i])
    end
    vline!([win_pre + 1])
    xticks!(1:15:45, string.(-1:1:2))
    xlabel!("Time [s]")
    ylabel!("% ΔF/F")
    title !== nothing && title!(title)
    p
end