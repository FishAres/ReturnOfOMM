function sort_pred_vis(sel_cells, grat_act, type::String="a_cells", win_pre=15, early_peak=5, late_peak=7)
    sel_gratings = type == "a_cells" ? [1, 3] : [2, 4]
    cell_act = squeeze(nanmean(nanmean(grat_act[sel_cells, sel_gratings, win_pre:end, :], dims=4), dims=2))
    peaks = argmax.(eachrow(cell_act))

    pred_cells = sel_cells[findall(<=(early_peak), peaks)]
    vis_cells = sel_cells[findall(>=(late_peak), peaks)]
    return pred_cells, vis_cells
end

function get_pred_vis_cor(grat_act, flip_act, condition; sel_thresh=0.33, mn_act_win=16:20)
    a_cells, b_cells = get_a_b_cells(grat_act, sel_thresh=sel_thresh)
    a_p, a_v = sort_pred_vis(a_cells, grat_act)
    b_p, b_v = sort_pred_vis(b_cells, grat_act, "b_cells")
    @assert isempty(intersect(a_p, a_v, b_p, b_v))

    pred_cells, vis_cells = condition == 4 ? (b_p, a_v) : (a_p, b_v)
    p, v = map((pred_cells, vis_cells)) do x
        filter_nan_col(squeeze(nanmean(flip_act[x, 5, mn_act_win, :], dims=2)))
    end

    return cor(p, v, dims=2)
end