using MLJ, Suppressor

function get_grat_data(grating_acts; mn_window=16:20, mn_sub=5:10)
    grating_acts_mnsub = mean_subtract(grating_acts, mn_sub, dims=3)
    ga_mn = squeeze(nanmean(grating_acts_mnsub[:, :, mn_window, :], dims=3))

    grat_resps = reshape(ga_mn, size(ga_mn, 1), :)
    # first_nan = findfirst(isnan, grat_resps[1, :]) # first nan column
    targs = repeat(1:5, 1, size(ga_mn)[end])[:]

    # return grat_resps[:, 1:first_nan-1], targs
    return grat_resps, targs
end

function split_clean_data(grat_resps, targs; frac_train=0.85)
    if frac_train < 1
        (X_train, X_test), (y_train, y_test) = partition((grat_resps', targs), frac_train, multi=true, shuffle=true)

        train_inds = non_nan_rows(X_train)
        test_inds = non_nan_rows(X_test)

        X_train = X_train[train_inds, :]
        y_train = y_train[train_inds]
        X_test = X_test[test_inds, :]
        y_test = y_test[test_inds]

        return (X_train, y_train), (X_test, y_test)
    else
        grat_resps = grat_resps'
        test_inds = non_nan_rows(grat_resps)
        X_test = grat_resps[test_inds, :]
        y_test = targs[test_inds]
        return X_test, y_test
    end
end

function classify_grat_svm(train_data, test_data)
    (X_train, y_train) = train_data
    (X_test, y_test) = test_data

    modelType = MLJ.@load SVMClassifier pkg = MLJScikitLearnInterface verbosity = 0
    model = modelType()
    mach = machine(model, X_train, categorical(y_train))
    fit!(mach)

    ŷ = Vector{Int64}(predict(mach, X_test))
    return ŷ, y_test, mach
end


function get_flip_conf_matrix(mach, flip_acts, mn_start, mn_win_length)
    flip_data, flip_targs = get_grat_data(flip_acts; mn_window=mn_start:mn_start+mn_win_length)
    x_flip, y_flip = split_clean_data(flip_data, flip_targs, frac_train=1.0)
    ŷ_flip = Vector{Int64}(predict(mach, x_flip))
    return confusion_matrix(ŷ_flip, y_flip).mat
end

function classify_conds(act_dict; mn_start_inds=16:2:22, mn_win_length=5, frac_train=0.85, win_pre=15, win_post=30, mn_sub=5:10, conditions=1:4)
    cm_dict = nested_default_dict() # dict of confusion matrices
    cm_flip_dict = nested_default_dict() # as above but for flip traversals
    for condition in conditions
        for mn_start in mn_start_inds
            for animal in 1:length(act_dict)
                if haskey(act_dict[animal], condition)
                    println("Training on condition $(condition), animal $(animal), mn_start $(mn_start)")

                    grating_acts, flip_acts = get_cond_grat_act(act_dict, animal, condition; win_pre=win_pre, win_post=win_post)

                    grat_data, targs = get_grat_data(grating_acts; mn_sub=mn_sub, mn_window=mn_start:mn_start+mn_win_length)

                    train_data, test_data = split_clean_data(grat_data, targs; frac_train=frac_train)

                    if !isempty(train_data[1])

                        @time ŷ, y_test, mach = classify_grat_svm(train_data, test_data)
                        cm = confusion_matrix(ŷ, y_test).mat
                        cm_dict[condition][mn_start][animal] = cm

                        if condition in [2, 4, 5] && size(flip_acts)[end] > 0
                            cm_flip = get_flip_conf_matrix(mach, flip_acts, mn_start, mn_win_length)
                            cm_flip_dict[condition][mn_start][animal] = cm_flip
                        end
                    end
                end
            end
        end
    end
    return cm_dict, cm_flip_dict
end

"Get a dictionary of normalized confusion matrices"
function get_mean_cms(cm_dict, mn_start_inds; conditions=1:4)
    mn_dict = Dict()
    for condition in conditions
        mn_dict[condition] = []
        for mn_start in mn_start_inds
            cms = collect(values(cm_dict[condition][mn_start]))
            cms_n = map(x -> x ./ sum(x, dims=2), cms)
            push!(mn_dict[condition], cms_n)
        end
    end
    return mn_dict
end

function plot_accs(mn_dict, win_index; conditions=1:4, kwargs...)
    acc_array = [mn_dict[cond][win_index] for cond in conditions]
    accs = hcat([pad_array(mean.(diag.(acc)), (9, 1)) for acc in acc_array]...)

    plot(nanmean(accs, dims=1)[:], ribbon=sem(accs, dims=1), ylims=(0.2, 0.8); kwargs...)
    xlabel!("Condition")
    ylabel!("Accuracy")
end

function plot_accs!(mn_dict, win_index; conditions=1:4, kwargs...)
    acc_array = filter(!isempty, [mn_dict[cond][win_index] for cond in conditions])
    accs = hcat([pad_array(mean.(diag.(acc)), (9, 1)) for acc in acc_array]...)

    plot!(nanmean(accs, dims=1)[:], ribbon=sem(accs, dims=1), ylims=(0.2, 0.8); kwargs...)
    xlabel!("Condition")
    # ylabel!("Accuracy")
end


function run_allcond_classification(act_dict, mn_start_inds, mn_sub; conditions=1:4)
    cm_dict, cm_flip_dict = @suppress_err begin # suppress MLJ type warnings
        classify_conds(act_dict; mn_start_inds=mn_start_inds, win_pre=15, win_post=30, mn_sub=mn_sub,
            conditions=conditions)
    end
    return cm_dict, cm_flip_dict
end

function plot_class_results(mn_start_inds, cm_dict; conditions=1:4)
    "Time in seconds pre/post onset"
    ind_in_secs(k; win_pre=15) = round((mn_start_inds[k] - win_pre) / 15, digits=3)
    mn_dict = get_mean_cms(cm_dict, mn_start_inds, conditions=conditions)

    p = plot([plot_accs(mn_dict, k, conditions=conditions; title="$(ind_in_secs(k)) s", legend=false,
        ) for k in eachindex(mn_start_inds)]..., size=(600, 600))

    return p

end