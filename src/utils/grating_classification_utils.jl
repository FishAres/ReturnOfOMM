using MLJ

function get_grat_data(grating_acts; mn_window=16:20, mn_sub=5:10)
    grating_acts_mnsub = mean_subtract(grating_acts, mn_sub, dims=3)
    ga_mn = squeeze(nanmean(grating_acts_mnsub[:, :, mn_window, :], dims=3))

    grat_resps = reshape(ga_mn, size(ga_mn, 1), :)
    targs = repeat(1:5, 1, size(ga_mn)[end])[:]
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
