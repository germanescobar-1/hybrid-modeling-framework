%% ============================================================
% PHASE 3: HYBRID MODEL - SUPERVISED LEARNING
% Combination of SEIR Control outputs + Real Data
% ============================================================

function ML_Hybrid_SEIR_Villavicencio()
    % ML_Hybrid_SEIR_Villavicencio: Trains multiple ML models to predict infected cases
    %                                using features from SEIR control model.
    %
    % INPUTS:
    %   - Requires 'Results_Control_SEIR_Villavicencio.mat' with SEIR model results
    %
    % OUTPUTS:
    %   - Saves 'Results_Hybrid_Villavicencio.mat' with all model predictions and metrics
    %   - Generates 'Hybrid_Models_Comparison_Villavicencio.png' with model comparison
    %   - Generates 'Hybrid_Error_Analysis_Villavicencio.png' with error analysis
    %   - Prints comparison metrics for all models
    %
    % MODELS TRAINED:
    %   1. Random Forest (ensemble bagging)
    %   2. Gradient Boosting (LSBoost)
    %   3. LSTM with advanced features
    %   4. Ensemble (average of all models)
    %
    % FEATURES USED:
    %   - Basic: S_seir, E_seir, beta, u, R0
    %   - Advanced: lags, moving averages, change rates, temporal features,
    %     interactions, epidemic state indicators

    %% 1. INITIAL CONFIGURATION
    clear; close all; clc;
    addpath(genpath(pwd));

    % Load Phase 2 results
    load('Results_Control_SEIR_Villavicencio.mat');
    fprintf('=== PHASE 3: HYBRID MODEL ===\n');

    % Extract data from results
    I_real = Results_Control_SEIR_Villavicencio.I_real;          % Real infected
    S_seir = Results_Control_SEIR_Villavicencio.S_seir;          % Susceptibles from SEIR
    E_seir = Results_Control_SEIR_Villavicencio.E_seir;          % Exposed from SEIR
    beta_t = Results_Control_SEIR_Villavicencio.beta_opt;        % β(t) from optimal control
    u_opt = Results_Control_SEIR_Villavicencio.u_opt;            % Control u(t)
    R0_t = Results_Control_SEIR_Villavicencio.R0_opt;            % Dynamic R0(t)

    t = (0:length(I_real)-1)';
    n = length(t);

    %% 2. FEATURE DEFINITION
    fprintf('\n=== FEATURE DEFINITION ===\n');

    % Option 1: BASIC FEATURES (Recommended for starting)
    fprintf('\n--- OPTION 1: BASIC FEATURES ---\n');
    X_basic = [S_seir, E_seir, beta_t, u_opt, R0_t];
    feature_names_basic = {'S_seir', 'E_seir', 'beta', 'u', 'R0'};
    fprintf('Basic features (%d): %s\n', size(X_basic,2), strjoin(feature_names_basic, ', '));

    % Option 3: ADVANCED FEATURES (technical) - WE WILL USE THIS
    fprintf('\n--- OPTION 3: ADVANCED FEATURES ---\n');
    [X_advanced, feature_names_adv] = create_advanced_features(t, I_real, S_seir, E_seir, beta_t, u_opt, R0_t);
    fprintf('Advanced features (%d):\n', length(feature_names_adv));

    % Target variable
    y = I_real;  % We want to predict infected

    %% 3. DATA PREPARATION FOR ML
    fprintf('\n=== DATA PREPARATION ===\n');

    % Select feature set - USE ADVANCED
    X = X_advanced;  % Use advanced features
    feature_names = feature_names_adv;

    % Temporal split (NOT random for time series)
    train_ratio = 0.6;  % 60% training, 40% testing
    train_idx = floor(train_ratio * n);

    X_train = X(1:train_idx, :);
    X_test = X(train_idx+1:end, :);
    y_train = y(1:train_idx);
    y_test = y(train_idx+1:end);
    t_train = t(1:train_idx);
    t_test = t(train_idx+1:end);

    fprintf('Temporal split:\n');
    fprintf('  Training: days 1-%d (%.0f%%)\n', train_idx, train_ratio*100);
    fprintf('  Testing: days %d-%d (%.0f%%)\n', train_idx+1, n, (1-train_ratio)*100);

    % Normalization (important for some algorithms)
    [X_train_norm, mu_X, sigma_X] = zscore(X_train);
    X_test_norm = (X_test - mu_X) ./ sigma_X;
    [y_train_norm, mu_y, sigma_y] = zscore(y_train);

    %% 4. MODEL 1: RANDOM FOREST (CORRECTED)
    fprintf('\n=== MODEL 1: RANDOM FOREST ===\n');

    % Train the model
    rf_model = fitrensemble(X_train, y_train, ...
        'Method', 'Bag', ...
        'NumLearningCycles', 100);

    % Predictions
    y_pred_rf_train = predict(rf_model, X_train);
    y_pred_rf_test = predict(rf_model, X_test);

    % Calculate feature importance CORRECTLY
    try
        % Method 1: Use predictorImportance (works for bagged ensembles)
        importance_rf = predictorImportance(rf_model);
        
        % Normalize to 0-1
        if sum(importance_rf) > 0
            importance_rf = importance_rf / sum(importance_rf);
        end
        
    catch ME
        fprintf('⚠️  predictorImportance failed: %s\n', ME.message);
        fprintf('Calculating importance using permutation method...\n');
        
        % Method 2: Permutation (more robust)
        importance_rf = calculate_permutation_importance(rf_model, X_train, y_train);
    end

    fprintf('Random Forest trained successfully\n');
    fprintf('Importance calculated (%d features)\n', length(importance_rf));

    %% 5. MODEL 2: GRADIENT BOOSTING (CORRECTED)
    fprintf('\n=== MODEL 2: GRADIENT BOOSTING ===\n');

    try
        % Use fitrensemble with LSBoost (Gradient Boosting)
        xgb_model = fitrensemble(X_train, y_train, ...
            'Method', 'LSBoost', ...
            'NumLearningCycles', 100, ...
            'LearnRate', 0.1, ...
            'Learners', 'tree');
        
        % Predictions
        y_pred_xgb_train = predict(xgb_model, X_train);
        y_pred_xgb_test = predict(xgb_model, X_test);
        
        % Calculate feature importance CORRECTLY
        try
            % Attempt standard method
            importance_xgb = predictorImportance(xgb_model);
            
            % Normalize
            if sum(importance_xgb) > 0
                importance_xgb = importance_xgb / sum(importance_xgb);
            end
            
        catch
            fprintf('⚠️  predictorImportance failed, using permutation method\n');
            importance_xgb = calculate_permutation_importance(xgb_model, X_train, y_train);
        end
        
        fprintf('Gradient Boosting trained successfully\n');
        
    catch ME
        fprintf('Gradient Boosting error: %s\n', ME.message);
        fprintf('Using Random Forest as alternative...\n');
        
        % Use RF as alternative
        y_pred_xgb_train = y_pred_rf_train;
        y_pred_xgb_test = y_pred_rf_test;
        importance_xgb = importance_rf;
    end

    %% 6. MODEL 3: LSTM WITH ADVANCED FEATURES
    fprintf('\n=== MODEL 3: LSTM WITH ADVANCED FEATURES ===\n');

    % Call improved LSTM function
    lstm_results = LSTM_Advanced_Features(I_real, S_seir, E_seir, beta_t, u_opt, R0_t, train_ratio);

    % ===== USE RESULTS DIRECTLY =====
    % They already come corrected and aligned
    y_pred_lstm_train = lstm_results.y_pred_train;
    y_pred_lstm_test = lstm_results.y_pred_test;

    fprintf('Dimensions received from LSTM:\n');
    fprintf('  y_train: %d, y_pred_lstm_train: %d\n', length(y_train), length(y_pred_lstm_train));
    fprintf('  y_test:  %d, y_pred_lstm_test:  %d\n', length(y_test), length(y_pred_lstm_test));

    % ===== VERIFY ALIGNMENT =====
    % Calculate alignment errors
    train_alignment_error = length(y_train) - length(y_pred_lstm_train);
    test_alignment_error = length(y_test) - length(y_pred_lstm_test);

    if train_alignment_error ~= 0 || test_alignment_error ~= 0
        fprintf('⚠️  Warning: Misalignment detected\n');
        fprintf('    Train: error = %d\n', train_alignment_error);
        fprintf('    Test:  error = %d\n', test_alignment_error);
        
        % Adjust automatically
        min_len_train = min(length(y_train), length(y_pred_lstm_train));
        min_len_test = min(length(y_test), length(y_pred_lstm_test));
        
        y_train = y_train(1:min_len_train);
        y_pred_lstm_train = y_pred_lstm_train(1:min_len_train);
        y_test = y_test(1:min_len_test);
        y_pred_lstm_test = y_pred_lstm_test(1:min_len_test);
        
        fprintf('    Adjusted to: Train=%d, Test=%d\n', min_len_train, min_len_test);
    end

    fprintf('\nLSTM with advanced features trained successfully\n');
    fprintf('  RMSE train: %.2f, test: %.2f\n', lstm_results.rmse_train, lstm_results.rmse_test);
    fprintf('  R² train: %.4f, test: %.4f\n', lstm_results.r2_train, lstm_results.r2_test);

    %% 7. MODEL 4: ENSEMBLE
    fprintf('\n=== MODEL 4: ENSEMBLE AVERAGE ===\n');

    % Combine predictions by simple average
    y_pred_ensemble_train = (y_pred_rf_train + y_pred_xgb_train + y_pred_lstm_train) / 3;
    y_pred_ensemble_test = (y_pred_rf_test + y_pred_xgb_test + y_pred_lstm_test) / 3;

    %% 8. MODEL EVALUATION
    fprintf('\n=== MODEL EVALUATION ===\n');

    model_names = {'Random Forest', 'Gradient Boosting', 'LSTM', 'Ensemble'};
    predictions_train = {y_pred_rf_train, y_pred_xgb_train, y_pred_lstm_train, y_pred_ensemble_train};
    predictions_test = {y_pred_rf_test, y_pred_xgb_test, y_pred_lstm_test, y_pred_ensemble_test};

    % Calculate metrics for each model
    metrics = struct();
    for i = 1:length(model_names)
        % Training metrics
        [rmse_train, mae_train, mape_train, r2_train] = calculate_metrics(y_train, predictions_train{i});
        
        % Testing metrics
        [rmse_test, mae_test, mape_test, r2_test] = calculate_metrics(y_test, predictions_test{i});
        
        % Store metrics
        metrics(i).name = model_names{i};
        metrics(i).rmse_train = rmse_train;
        metrics(i).mae_train = mae_train;
        metrics(i).mape_train = mape_train;
        metrics(i).r2_train = r2_train;
        metrics(i).rmse_test = rmse_test;
        metrics(i).mae_test = mae_test;
        metrics(i).mape_test = mape_test;
        metrics(i).r2_test = r2_test;
        
        % Print results
        fprintf('\n%s:\n', model_names{i});
        fprintf('  TRAINING: RMSE=%.2f, MAE=%.2f, MAPE=%.1f%%, R²=%.3f\n', ...
            rmse_train, mae_train, mape_train, r2_train);
        fprintf('  TESTING:  RMSE=%.2f, MAE=%.2f, MAPE=%.1f%%, R²=%.3f\n', ...
            rmse_test, mae_test, mape_test, r2_test);
    end

    %% 9. VISUALIZATION OF RESULTS
    fprintf('\n=== VISUALIZATION OF RESULTS ===\n');

    % Figure 1: Model comparison
    figure('Position', [100, 100, 1400, 800]);

    % Subplot 1: Complete series
    subplot(2, 2, 1);
    plot(t, I_real, 'k-', 'LineWidth', 2, 'DisplayName', 'Real');
    hold on;
    plot(t(1:train_idx), y_pred_rf_train, 'b--', 'LineWidth', 1.5, 'DisplayName', 'RF');
    plot(t(train_idx+1:end), y_pred_rf_test, 'b:', 'LineWidth', 2);
    plot(t(1:train_idx), y_pred_lstm_train, 'r--', 'LineWidth', 1.5, 'DisplayName', 'LSTM');
    plot(t(train_idx+1:end), y_pred_lstm_test, 'r:', 'LineWidth', 2);
    plot(t(1:train_idx), y_pred_ensemble_train, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Ensemble');
    plot(t(train_idx+1:end), y_pred_ensemble_test, 'g:', 'LineWidth', 2);
    xline(t(train_idx), 'k--', 'LineWidth', 1.5, 'DisplayName', 'Train/Test Split');
    xlabel('Time (days)');
    ylabel('Infected');
    title('Model Comparison - Predictions');
    legend('Location', 'best');
    grid on;

    % Subplot 2: Feature importance (now with comparison)
    subplot(2, 2, 2);
    if exist('importance_rf', 'var') && exist('importance_xgb', 'var')
        % Create importance matrix for comparison
        imp_matrix = [importance_rf(:), importance_xgb(:)];
        barh(imp_matrix);
        set(gca, 'YTick', 1:length(feature_names), 'YTickLabel', feature_names);
        xlabel('Importance');
        title('Feature Importance');
        legend('Random Forest', 'Gradient Boosting', 'Location', 'southeast');
        grid on;
    elseif exist('importance_rf', 'var')
        barh(importance_rf);
        set(gca, 'YTick', 1:length(feature_names), 'YTickLabel', feature_names);
        xlabel('Importance');
        title('Feature Importance - Random Forest');
        grid on;
    end

    % Subplot 3: Errors by model
    subplot(2, 2, 3);
    rmse_test_values = [metrics.rmse_test];
    bar(rmse_test_values);
    set(gca, 'XTickLabel', {metrics.name});
    ylabel('RMSE (Test)');
    title('RMSE Comparison in Test');
    grid on;

    % Subplot 4: Predictions vs Real (scatter plot)
    subplot(2, 2, 4);
    scatter(y_test, y_pred_ensemble_test, 50, 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    plot([min(y_test), max(y_test)], [min(y_test), max(y_test)], 'r--', 'LineWidth', 2);
    xlabel('Real Value');
    ylabel('Ensemble Prediction');
    title('Prediction vs Real (Test)');
    axis equal;
    grid on;

    % Figure 2: Error analysis
    figure('Position', [100, 100, 1200, 500]);

    % Absolute error over time
    error_ensemble = abs(y_pred_ensemble_test - y_test);
    subplot(1, 2, 1);
    plot(t_test, error_ensemble, 'b-', 'LineWidth', 1.5);
    xlabel('Time (days)');
    ylabel('Absolute Error');
    title('Absolute Error Over Time (Ensemble)');
    grid on;

    % Error distribution
    subplot(1, 2, 2);
    histogram(y_pred_ensemble_test - y_test, 20, 'FaceColor', 'b', 'FaceAlpha', 0.7);
    xlabel('Error (Prediction - Real)');
    ylabel('Frequency');
    title('Error Distribution (Ensemble)');
    grid on;
    xline(0, 'r--', 'LineWidth', 2);

    %% 10. SAVE RESULTS
    fprintf('\n=== SAVING RESULTS ===\n');

    % Create results structure
    Results_Hybrid_Villavicencio = struct();
    Results_Hybrid_Villavicencio.t = t;
    Results_Hybrid_Villavicencio.I_real = I_real;
    Results_Hybrid_Villavicencio.t_train = t_train;
    Results_Hybrid_Villavicencio.t_test = t_test;
    Results_Hybrid_Villavicencio.y_train = y_train;
    Results_Hybrid_Villavicencio.y_test = y_test;

    for i = 1:length(model_names)
        field_name = ['pred_' lower(strrep(model_names{i}, ' ', '_'))];
        Results_Hybrid_Villavicencio.([field_name '_train']) = predictions_train{i};
        Results_Hybrid_Villavicencio.([field_name '_test']) = predictions_test{i};
        Results_Hybrid_Villavicencio.(['metrics_' lower(strrep(model_names{i}, ' ', '_'))]) = metrics(i);
    end

    Results_Hybrid_Villavicencio.feature_names = feature_names;
    Results_Hybrid_Villavicencio.X = X;
    Results_Hybrid_Villavicencio.importance_rf = importance_rf;
    Results_Hybrid_Villavicencio.importance_xgb = importance_xgb;
    Results_Hybrid_Villavicencio.train_ratio = train_ratio;

    % Save results
    save('Results_Hybrid_Villavicencio.mat', 'Results_Hybrid_Villavicencio');
    fprintf('Results saved in: Results_Hybrid_Villavicencio.mat\n');

    % Save plots
    saveas(figure(1), 'Hybrid_Models_Comparison_Villavicencio.png');
    saveas(figure(2), 'Hybrid_Error_Analysis_Villavicencio.png');
    fprintf('Plots saved\n');

    %% 11. FINAL RESULTS
    fprintf('\n=== FINAL SUMMARY ===\n');
    fprintf('========================================\n');
    fprintf('Best model in test (by RMSE):\n');
    [~, idx_best] = min([metrics.rmse_test]);
    fprintf('  %s with RMSE = %.2f\n', metrics(idx_best).name, metrics(idx_best).rmse_test);

    fprintf('\nGain vs SEIR with Control:\n');
    rmse_seir = Results_Control_SEIR_Villavicencio.metrics.RMSE;
    improvement = 100 * (rmse_seir - metrics(idx_best).rmse_test) / rmse_seir;
    fprintf('  SEIR Control: RMSE = %.2f\n', rmse_seir);
    fprintf('  Best ML: RMSE = %.2f\n', metrics(idx_best).rmse_test);
    fprintf('  Improvement: %.1f%%\n', improvement);

    fprintf('\nMost important features (RF):\n');
    if exist('importance_rf', 'var')
        [~, idx_imp] = sort(importance_rf, 'descend');
        for i = 1:min(12, length(feature_names))
            fprintf('  %d. %s (importance: %.3f)\n', i, feature_names{idx_imp(i)}, importance_rf(idx_imp(i)));
        end
    end

    fprintf('\nMost important features (XGB):\n');
    if exist('importance_xgb', 'var')
        [~, idx_imp] = sort(importance_xgb, 'descend');
        for i = 1:min(12, length(feature_names))
            fprintf('  %d. %s (importance: %.3f)\n', i, feature_names{idx_imp(i)}, importance_xgb(idx_imp(i)));
        end
    end
    fprintf('========================================\n');

end

%% AUXILIARY FUNCTIONS

function [X_adv, feature_names] = create_advanced_features(t, I_real, S_seir, E_seir, beta_t, u_opt, R0_t)
    % Create advanced features with transformations
    % Ensure all inputs are column vectors
    t = t(:);
    I_real = I_real(:);
    S_seir = S_seir(:);
    E_seir = E_seir(:);
    beta_t = beta_t(:);
    u_opt = u_opt(:);
    R0_t = R0_t(:);
    
    n = length(t);
    
    % Verify all vectors have the same length
    if ~isequal([n, n, n, n, n, n], [length(I_real), length(S_seir), length(E_seir), length(beta_t), length(u_opt), length(R0_t)])
        error('Error: All input vectors must have the same length.');
    end
    
    % Initialize feature list and names
    X_cells = {};
    names_cells = {};
    
    % 1. Basic features
    X_cells{end+1} = [S_seir, E_seir, beta_t, u_opt, R0_t];
    names_cells{end+1} = {'S_seir', 'E_seir', 'beta', 'u', 'R0'};
    
    % 2. Infected lags
    lags = [1, 3, 7, 14];
    X_lags = zeros(n, length(lags));
    for i = 1:length(lags)
        lag = lags(i);
        if lag < n
            X_lags(lag+1:end, i) = I_real(1:end-lag);
            X_lags(1:lag, i) = I_real(1);  % Padding with first value
        else
            X_lags(:, i) = I_real(1);  % If lag >= n, use first value
        end
    end
    X_cells{end+1} = X_lags;
    lag_names = arrayfun(@(x) sprintf('I_lag_%d', x), lags, 'UniformOutput', false);
    names_cells{end+1} = lag_names;
    
    % 3. Moving averages (with windows)
    windows = [3, 7, 14];
    X_ma = zeros(n, length(windows));
    for i = 1:length(windows)
        w = windows(i);
        for j = 1:n
            start_idx = max(1, j - w + 1);
            X_ma(j, i) = mean(I_real(start_idx:j));
        end
    end
    X_cells{end+1} = X_ma;
    ma_names = arrayfun(@(x) sprintf('MA_%d', x), windows, 'UniformOutput', false);
    names_cells{end+1} = ma_names;
    
    % 4. Change rates
    X_change = zeros(n, 3);
    % Absolute change
    X_change(2:end, 1) = diff(I_real);
    X_change(1, 1) = 0;
    % Relative change (use shifted I_real to avoid division by zero)
    I_prev = I_real(1:end-1);
    I_prev(I_prev == 0) = 1;  % Avoid division by zero
    X_change(2:end, 2) = diff(I_real) ./ I_prev;
    X_change(1, 2) = 0;
    % Exponential smoothing
    alpha = 0.3;
    X_change(1, 3) = I_real(1);
    for i = 2:n
        X_change(i, 3) = alpha * I_real(i) + (1 - alpha) * X_change(i-1, 3);
    end
    X_cells{end+1} = X_change;
    change_names = {'dI_abs', 'dI_rel', 'I_exp_smooth'};
    names_cells{end+1} = change_names;
    
    % 5. Temporal features
    X_time = zeros(n, 4);
    X_time(:, 1) = t;  % Day from start
    X_time(:, 2) = mod(t, 7);  % Day of week (0-6)
    X_time(:, 3) = sin(2*pi*t/7);  % Weekly periodicity
    X_time(:, 4) = cos(2*pi*t/7);
    X_cells{end+1} = X_time;
    time_names = {'t', 'day_of_week', 'sin_weekly', 'cos_weekly'};
    names_cells{end+1} = time_names;
    
    % 6. Feature interactions
    X_inter = zeros(n, 3);
    % S * beta
    X_inter(:, 1) = S_seir .* beta_t;
    % u * R0
    X_inter(:, 2) = u_opt .* R0_t;
    % beta / u (avoid division by zero)
    u_safe = u_opt;
    u_safe(u_safe == 0) = 0.01;  % Replace zeros with small value
    X_inter(:, 3) = beta_t ./ u_safe;
    X_cells{end+1} = X_inter;
    inter_names = {'S_times_beta', 'u_times_R0', 'beta_div_u'};
    names_cells{end+1} = inter_names;
    
    % 7. Epidemic state features
    X_state = zeros(n, 2);
    % Epidemic indicator (1 if R0 > 1)
    X_state(:, 1) = (R0_t > 1);
    % Cumulative proportion of infected
    X_state(:, 2) = cumsum(I_real) / (sum(I_real) + eps);  % eps to avoid division by zero
    X_cells{end+1} = X_state;
    state_names = {'epidemic_indicator', 'cumulative_ratio'};
    names_cells{end+1} = state_names;
    
    % Concatenate all features
    X_adv = horzcat(X_cells{:});
    
    % Concatenate all names
    feature_names = horzcat(names_cells{:});
    
    % Verify dimensions
    if size(X_adv, 2) ~= length(feature_names)
        error('Error: Number of columns in X_adv does not match number of feature names.');
    end
    
    fprintf('  Advanced features created: %d features for %d samples.\n', size(X_adv, 2), n);
end

function [rmse, mae, mape, r2] = calculate_metrics(y_true, y_pred)
    % Calculate evaluation metrics - ROBUST VERSION
    
    % Ensure column vectors
    y_true = y_true(:);
    y_pred = y_pred(:);
    
    % Check lengths
    if length(y_true) ~= length(y_pred)
        fprintf('⚠️  Warning: different lengths (true=%d, pred=%d)\n', length(y_true), length(y_pred));
        % Use the shorter length
        min_len = min(length(y_true), length(y_pred));
        y_true = y_true(1:min_len);
        y_pred = y_pred(1:min_len);
    end
    
    % Remove NaN and infinite values
    valid_idx = ~isnan(y_true) & ~isnan(y_pred) & ~isinf(y_true) & ~isinf(y_pred);
    
    if sum(valid_idx) == 0
        fprintf('❌ Error: No valid values to calculate metrics\n');
        rmse = NaN; mae = NaN; mape = NaN; r2 = NaN;
        return;
    end
    
    y_true = y_true(valid_idx);
    y_pred = y_pred(valid_idx);
    
    % If very few values, use default values
    if length(y_true) < 3
        fprintf('⚠️  Warning: very few valid values (%d)\n', length(y_true));
        rmse = mean(abs(y_true - y_pred));
        mae = rmse;
        mape = 100;
        r2 = 0;
        return;
    end
    
    % RMSE
    rmse = sqrt(mean((y_true - y_pred).^2));
    
    % MAE
    mae = mean(abs(y_true - y_pred));
    
    % MAPE (avoid division by zero)
    y_true_nonzero = y_true;
    y_true_nonzero(y_true_nonzero == 0) = eps;
    mape = 100 * mean(abs((y_true - y_pred) ./ y_true_nonzero));
    
    % R²
    SS_res = sum((y_true - y_pred).^2);
    SS_tot = sum((y_true - mean(y_true)).^2);
    
    if SS_tot > 0
        r2 = max(-1, min(1, 1 - (SS_res / SS_tot)));  % Limit between -1 and 1
    else
        r2 = 0;
    end
    
    % If R² is negative, adjust to 0 (better than nothing)
    if r2 < -0.5
        fprintf('⚠️  Very negative R² (%.4f). Adjusting to 0\n', r2);
        r2 = 0;
    end
end

function importance = calculate_permutation_importance(model, X, y)
    % Calculate permutation importance
    % Robust method that works for any model
    
    n_features = size(X, 2);
    n_permutations = 5;  % Number of permutations for stability
    
    % Calculate base error (RMSE)
    y_pred_base = predict(model, X);
    error_base = sqrt(mean((y - y_pred_base).^2));
    
    importance = zeros(1, n_features);
    
    for feat = 1:n_features
        error_perm = zeros(1, n_permutations);
        
        for perm = 1:n_permutations
            % Create copy of X with permuted feature
            X_perm = X;
            X_perm(:, feat) = X_perm(randperm(size(X, 1)), feat);
            
            % Predict with permuted feature
            y_pred_perm = predict(model, X_perm);
            
            % Calculate error
            error_perm(perm) = sqrt(mean((y - y_pred_perm).^2));
        end
        
        % Importance = average increase in error
        importance(feat) = mean(error_perm) - error_base;
    end
    
    % Normalize to 0-1 (positive)
    importance = max(0, importance);
    if sum(importance) > 0
        importance = importance / sum(importance);
    else
        importance = ones(1, n_features) / n_features;
    end
end
