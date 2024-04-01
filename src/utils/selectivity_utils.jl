"""
Utility functions for selectivity indices
"""
selectivity_index(a, b) = (a - b) ./ (a + b)

function get_selectivity_index(grat_acts; thresh=0.01, mn_window=20:25)
    B_act = squeeze(nanmean(grat_acts[:, [2, 4], mn_window, :], dims=3))
    A_act = squeeze(nanmean(grat_acts[:, [1, 3], mn_window, :], dims=3))

    A = mean(nanmean(A_act, dims=3), dims=2) |> squeeze
    B = mean(nanmean(B_act, dims=3), dims=2) |> squeeze

    si = map(x -> maximum(x) >= thresh ? selectivity_index(x[1], x[2]) : 0, eachrow([A B]))
    return si
end

function plot_a_b_cells(grat_acts, a_cells, b_cells)
    pa = plot_mean_grat_act(grat_acts, a_cells; title="A cells")
    ylims!(-0.03, 0.08)
    pb = plot_mean_grat_act(grat_acts, b_cells; title="B cells")
    ylims!(-0.03, 0.08)
    plot(pa, pb)
end