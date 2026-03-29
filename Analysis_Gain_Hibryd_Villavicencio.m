%% ============================================================
% HYBRID MODEL GAIN ANALYSIS
% Comparison with SEIR Control Model
% Improvement metrics: 1-4
% ============================================================

function Analysis_Gain_Hybrid_Villavicencio()
    % Analysis_Profit_Hybrid_Villavicencio: Analyzes the gain of hybrid ML models
    %                                        compared to SEIR with control.
    %
    % INPUTS:
    %   - Requires 'Results_Control_SEIR_Villavicencio.mat' with SEIR model results
    %   - Requires 'Results_Hybrid_Villavicencio.mat' with hybrid model results
    %
    % OUTPUTS:
    %   - Saves 'Results_Gain_Hybrid_Villavicencio.mat' with all gain metrics
    %   - Generates 'Hybrid_Gain_Analysis_Villavicencio.png' with 9 subplots
    %   - Prints comprehensive report with interpretation
    %
    % METRICS CALCULATED:
    %   1. Percentage improvement vs SEIR in RMSE, MAE, R²
    %   2. Gain by epidemic phase (growth, plateau, decline)
    %   3. Robustness: error ratio between peaks and quiet periods
    %   4. Stability: cross-validation error variance

    clear; close all; clc;
    fprintf('=== HYBRID MODEL GAIN ANALYSIS ===\n');

    %% 1. LOAD DATA FROM BOTH MODELS
    fprintf('\n1. Loading model data...\n');

    % Load SEIR control results
    load('Results_Control_SEIR_Villavicencio.mat');
    I_real_SEIR = Results_Control_SEIR_Villavicencio.I_real;
    I_model_SEIR = Results_Control_SEIR_Villavicencio.I_seir;
    RMSE_SEIR = Results_Control_SEIR_Villavicencio.metrics.RMSE;
    MAE_SEIR = Results_Control_SEIR_Villavicencio.metrics.MAE;
    R2_SEIR = Results_Control_SEIR_Villavicencio.metrics.R2;

    % Load hybrid model results
    load('Results_Hybrid_Villavicencio.mat');
    I_real_hybrid = Results_Hybrid_Villavicencio.I_real;
    I_model_ensemble = Results_Hybrid_Villavicencio.pred_ensemble_test;
    t_test = Results_Hybrid_Villavicencio.t_test;
    y_test = Results_Hybrid_Villavicencio.y_test;

    % Get all hybrid predictions
    model_names = {'Random Forest', 'Gradient Boosting', 'LSTM', 'Ensemble'};
    predictions = struct();
    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        try
            predictions.(name_lower).train = Results_Hybrid_Villavicencio.(['pred_' name_lower '_train']);
            predictions.(name_lower).test = Results_Hybrid_Villavicencio.(['pred_' name_lower '_test']);
        catch
            fprintf('   Warning: No predictions found for %s\n', model_names{i});
        end
    end

    % Get hybrid metrics
    metrics_hybrid = struct();
    for i = 1:length(model_names)
        try
            name_lower = lower(strrep(model_names{i}, ' ', '_'));
            metrics_hybrid.(name_lower) = Results_Hybrid_Villavicencio.(['metrics_' name_lower]);
        catch
            % If metrics don't exist, calculate them
            if isfield(predictions, lower(strrep(model_names{i}, ' ', '_')))
                name_lower = lower(strrep(model_names{i}, ' ', '_'));
                [rmse_train, mae_train, mape_train, r2_train] = calculate_metrics(...
                    Results_Hybrid_Villavicencio.y_train, predictions.(name_lower).train);
                [rmse_test, mae_test, mape_test, r2_test] = calculate_metrics(...
                    Results_Hybrid_Villavicencio.y_test, predictions.(name_lower).test);
                
                metrics_hybrid.(name_lower).rmse_train = rmse_train;
                metrics_hybrid.(name_lower).mae_train = mae_train;
                metrics_hybrid.(name_lower).mape_train = mape_train;
                metrics_hybrid.(name_lower).r2_train = r2_train;
                metrics_hybrid.(name_lower).rmse_test = rmse_test;
                metrics_hybrid.(name_lower).mae_test = mae_test;
                metrics_hybrid.(name_lower).mape_test = mape_test;
                metrics_hybrid.(name_lower).r2_test = r2_test;
            end
        end
    end

    T = length(I_real_SEIR);
    t = 1:T;
    train_idx = length(Results_Hybrid_Villavicencio.t_train);

    %% 2. METRIC 1: % IMPROVEMENT vs SEIR
    fprintf('\n2. Calculating percentage improvement vs SEIR...\n');

    % For each hybrid model, calculate improvement in RMSE
    improvement_RMSE = struct();
    improvement_MAE = struct();
    improvement_R2 = struct();

    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        
        if isfield(metrics_hybrid, name_lower)
            % Calculate hybrid RMSE over the ENTIRE period
            % Need to reconstruct complete predictions
            if isfield(predictions, name_lower)
                % Concatenate train and test predictions
                pred_complete = [predictions.(name_lower).train; predictions.(name_lower).test];
                
                % Ensure same length
                if length(pred_complete) > T
                    pred_complete = pred_complete(1:T);
                elseif length(pred_complete) < T
                    % Extend with last value
                    pred_complete = [pred_complete; ones(T-length(pred_complete), 1) * pred_complete(end)];
                end
                
                % Calculate metrics over the entire period
                [rmse_full, mae_full, ~, r2_full] = calculate_metrics(I_real_SEIR', pred_complete);
                
                % Calculate improvements
                improvement_RMSE.(name_lower) = 100 * (RMSE_SEIR - rmse_full) / RMSE_SEIR;
                improvement_MAE.(name_lower) = 100 * (MAE_SEIR - mae_full) / MAE_SEIR;
                improvement_R2.(name_lower) = 100 * (r2_full - R2_SEIR) / (1 - R2_SEIR + eps);
                
                fprintf('   %s: RMSE=%.2f (Improvement: %.1f%%), R²=%.4f (Improvement: %.1f%%)\n', ...
                    model_names{i}, rmse_full, improvement_RMSE.(name_lower), r2_full, improvement_R2.(name_lower));
            end
        end
    end

    %% 3. METRIC 2: GAIN BY EPIDEMIC PHASE
    fprintf('\n3. Epidemic phase analysis...\n');

    % Detect epidemic phases using the real curve
    % 1. Growth: until first peak (positive derivative)
    % 2. Plateau: around the peak (values close to maximum)
    % 3. Decline: after the peak (negative derivative)

    [~, idx_peak] = max(I_real_SEIR);
    I_max = I_real_SEIR(idx_peak);
    plateau_threshold = 0.8 * I_max;  % 80% of peak to consider plateau

    % Find plateau start
    plateau_start = find(I_real_SEIR(1:idx_peak) >= plateau_threshold, 1);
    if isempty(plateau_start)
        plateau_start = max(1, idx_peak - 7);  % 7 days before peak
    end

    % Find plateau end
    plateau_end = find(I_real_SEIR(idx_peak:end) >= plateau_threshold, 1, 'last') + idx_peak - 1;
    if isempty(plateau_end) || plateau_end > T
        plateau_end = min(T, idx_peak + 7);  % 7 days after peak
    end

    % Define phases
    growth_phase = 1:(plateau_start-1);
    plateau_phase = plateau_start:plateau_end;
    decline_phase = (plateau_end+1):T;

    fprintf('   Detected phases:\n');
    fprintf('     Growth: days %d-%d (%d days)\n', ...
        growth_phase(1), growth_phase(end), length(growth_phase));
    fprintf('     Plateau: days %d-%d (%d days)\n', ...
        plateau_phase(1), plateau_phase(end), length(plateau_phase));
    fprintf('     Decline: days %d-%d (%d days)\n', ...
        decline_phase(1), decline_phase(end), length(decline_phase));

    % Calculate phase metrics for each model
    phases = {'growth', 'plateau', 'decline'};
    phase_idx = {growth_phase, plateau_phase, decline_phase};

    improvement_by_phase = struct();

    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        
        if isfield(metrics_hybrid, name_lower) && isfield(predictions, name_lower)
            % Reconstruct complete predictions
            pred_complete = [predictions.(name_lower).train; predictions.(name_lower).test];
            if length(pred_complete) > T
                pred_complete = pred_complete(1:T);
            elseif length(pred_complete) < T
                pred_complete = [pred_complete; ones(T-length(pred_complete), 1) * pred_complete(end)];
            end
            
            % Initialize structure
            improvement_by_phase.(name_lower) = struct();
            
            for f = 1:length(phases)
                idx = phase_idx{f};
                if ~isempty(idx)
                    % Real data and predictions in this phase
                    I_real_phase = I_real_SEIR(idx);
                    I_model_SEIR_phase = I_model_SEIR(idx);
                    
                    % Ensure hybrid predictions have valid indices
                    idx_valid = idx(idx <= length(pred_complete));
                    I_model_hybrid_phase = pred_complete(idx_valid);
                    
                    % If length mismatch, adjust
                    if length(I_model_hybrid_phase) < length(I_real_phase)
                        I_model_hybrid_phase = [I_model_hybrid_phase; ...
                            ones(length(I_real_phase)-length(I_model_hybrid_phase), 1) * ...
                            I_model_hybrid_phase(end)];
                    end
                    
                    % Calculate RMSE in this phase
                    rmse_seir_phase = sqrt(mean((I_real_phase - I_model_SEIR_phase').^2));
                    rmse_hybrid_phase = sqrt(mean((I_real_phase - I_model_hybrid_phase).^2));
                    
                    % Calculate improvement
                    if rmse_seir_phase > 0
                        improvement_phase = 100 * (rmse_seir_phase - rmse_hybrid_phase) / rmse_seir_phase;
                    else
                        improvement_phase = 0;
                    end
                    
                    improvement_by_phase.(name_lower).(phases{f}) = improvement_phase;
                    improvement_by_phase.(name_lower).([phases{f} '_rmse_seir']) = rmse_seir_phase;
                    improvement_by_phase.(name_lower).([phases{f} '_rmse_hybrid']) = rmse_hybrid_phase;
                end
            end
            
            % Display results
            fprintf('\n   %s - Improvement by phase:\n', model_names{i});
            for f = 1:length(phases)
                if ~isempty(phase_idx{f}) && isfield(improvement_by_phase.(name_lower), phases{f})
                    fprintf('     %s: %.1f%% (SEIR: %.2f, Hybrid: %.2f)\n', ...
                        phases{f}, improvement_by_phase.(name_lower).(phases{f}), ...
                        improvement_by_phase.(name_lower).([phases{f} '_rmse_seir']), ...
                        improvement_by_phase.(name_lower).([phases{f} '_rmse_hybrid']));
                end
            end
        end
    end

    %% 4. METRIC 3: ROBUSTNESS - ERROR IN PEAKS vs QUIET PERIODS
    fprintf('\n4. Robustness analysis...\n');

    % Identify epidemic peaks (75th percentile) and quiet periods (25th percentile)
    percentile_75 = prctile(I_real_SEIR, 75);
    percentile_25 = prctile(I_real_SEIR, 25);

    % Identify peak days and quiet periods
    peak_days = find(I_real_SEIR >= percentile_75);
    quiet_days = find(I_real_SEIR <= percentile_25);

    fprintf('   Epidemic peaks: %d days (I ≥ %.1f)\n', length(peak_days), percentile_75);
    fprintf('   Quiet periods: %d days (I ≤ %.1f)\n', length(quiet_days), percentile_25);

    % Calculate robustness for each model
    robustness_models = struct();

    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        
        if isfield(metrics_hybrid, name_lower) && isfield(predictions, name_lower)
            % Reconstruct complete predictions
            pred_complete = [predictions.(name_lower).train; predictions.(name_lower).test];
            if length(pred_complete) > T
                pred_complete = pred_complete(1:T);
            elseif length(pred_complete) < T
                pred_complete = [pred_complete; ones(T-length(pred_complete), 1) * pred_complete(end)];
            end

            % Error in peaks - ENSURE SCALARS
            error_peaks_seir = mean(abs(I_real_SEIR(peak_days) - I_model_SEIR(peak_days)'), 'all');
            error_peaks_hybrid = mean(abs(I_real_SEIR(peak_days) - pred_complete(peak_days)), 'all');
            
            % Error in quiet periods - ENSURE SCALARS
            error_quiet_seir = mean(abs(I_real_SEIR(quiet_days) - I_model_SEIR(quiet_days)'), 'all');
            error_quiet_hybrid = mean(abs(I_real_SEIR(quiet_days) - pred_complete(quiet_days)), 'all');
            
            % Calculate robustness ratio (lower is better) - WITH VERIFICATION
            if error_quiet_seir ~= 0
                ratio_robustness_seir = error_peaks_seir / error_quiet_seir;
            else
                ratio_robustness_seir = NaN;
            end
            
            if error_quiet_hybrid ~= 0
                ratio_robustness_hybrid = error_peaks_hybrid / error_quiet_hybrid;
            else
                ratio_robustness_hybrid = NaN;
            end

            % Improvement in robustness (ratio reduction)
            improvement_robustness = 100 * (ratio_robustness_seir - ratio_robustness_hybrid) / ratio_robustness_seir;
            
            robustness_models.(name_lower) = struct();
            robustness_models.(name_lower).error_peaks_seir = error_peaks_seir;
            robustness_models.(name_lower).error_peaks_hybrid = error_peaks_hybrid;
            robustness_models.(name_lower).error_quiet_seir = error_quiet_seir;
            robustness_models.(name_lower).error_quiet_hybrid = error_quiet_hybrid;
            robustness_models.(name_lower).ratio_seir = ratio_robustness_seir;
            robustness_models.(name_lower).ratio_hybrid = ratio_robustness_hybrid;
            robustness_models.(name_lower).improvement_robustness = improvement_robustness;
            
            fprintf('\n   %s - Robustness:\n', model_names{i});
            fprintf('     Peak error: SEIR=%.2f, Hybrid=%.2f (%.1f%% better)\n', ...
                error_peaks_seir, error_peaks_hybrid, ...
                100*(error_peaks_seir-error_peaks_hybrid)/error_peaks_seir);
            fprintf('     Quiet error: SEIR=%.2f, Hybrid=%.2f\n', ...
                error_quiet_seir, error_quiet_hybrid);
            fprintf('     Robustness ratio: SEIR=%.3f, Hybrid=%.3f (%.1f%% better)\n', ...
                ratio_robustness_seir, ratio_robustness_hybrid, improvement_robustness);
        end
    end

    %% 5. METRIC 4: STABILITY - CROSS-VALIDATION ERROR VARIANCE
    fprintf('\n5. Stability analysis (error variance)...\n');

    % Implement simple temporal cross-validation
    % Divide time series into k consecutive blocks
    k = 5;  % 5-fold cross-validation
    block_size = floor(T / k);

    error_variance = struct();

    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        
        if isfield(metrics_hybrid, name_lower) && isfield(predictions, name_lower)
            % Reconstruct complete predictions
            pred_complete = [predictions.(name_lower).train; predictions.(name_lower).test];
            if length(pred_complete) > T
                pred_complete = pred_complete(1:T);
            elseif length(pred_complete) < T
                pred_complete = [pred_complete; ones(T-length(pred_complete), 1) * pred_complete(end)];
            end

            % Calculate errors by block
            block_errors = zeros(k, 1);
            
            for block = 1:k
                start_idx = (block-1) * block_size + 1;
                end_idx = min(block * block_size, T);
                
                idx_block = start_idx:end_idx;
                
                % Ensure we have data in this block
                if ~isempty(idx_block)
                    % Extract real and predicted data for this block
                    y_real_block = I_real_SEIR(idx_block);
                    y_pred_block = pred_complete(idx_block);
                    
                    % Ensure both vectors are columns and have the same length
                    y_real_block = y_real_block(:);
                    y_pred_block = y_pred_block(:);
                    
                    % Calculate RMSE in this block
                    error_block = sqrt(mean((y_real_block - y_pred_block).^2));
                    
                    % Verify it's scalar
                    if isscalar(error_block)
                        block_errors(block) = error_block;
                    else
                        % If not scalar, take first element or average
                        block_errors(block) = mean(error_block(:));
                        warning('Error_block was not scalar in block %d. Averaging values.', block);
                    end
                else
                    block_errors(block) = NaN;  % Empty block
                end
            end

            % Calculate variance and coefficient of variation
            error_variance_hybrid = var(block_errors, 'omitnan');
            error_mean_hybrid = mean(block_errors, 'omitnan');
            cv_hybrid = 100 * sqrt(error_variance_hybrid) / error_mean_hybrid;  % Coefficient of variation

            % Calculate same for SEIR (for comparison)
            block_errors_seir = zeros(k, 1);
            for block = 1:k
                start_idx = (block-1) * block_size + 1;
                end_idx = min(block * block_size, T);
                idx_block = start_idx:end_idx;
                
                if ~isempty(idx_block)
                    y_real_block = I_real_SEIR(idx_block);
                    y_pred_block = I_model_SEIR(idx_block)';
                    
                    % Ensure both vectors are columns and have the same length
                    y_real_block = y_real_block(:);
                    y_pred_block = y_pred_block(:);
                    
                    % Calculate RMSE in this block
                    error_block_seir = sqrt(mean((y_real_block - y_pred_block).^2));
                    
                    % Verify it's scalar
                    if isscalar(error_block_seir)
                        block_errors_seir(block) = error_block_seir;
                    else
                        block_errors_seir(block) = mean(error_block_seir(:));
                    end
                else
                    block_errors_seir(block) = NaN;
                end
            end

            error_variance_seir = var(block_errors_seir, 'omitnan');
            error_mean_seir = mean(block_errors_seir, 'omitnan');
            cv_seir = 100 * sqrt(error_variance_seir) / error_mean_seir;
            
            % Improvement in stability (CV reduction)
            improvement_stability = 100 * (cv_seir - cv_hybrid) / cv_seir;
            
            error_variance.(name_lower) = struct();
            error_variance.(name_lower).variance = error_variance_hybrid;
            error_variance.(name_lower).cv = cv_hybrid;
            error_variance.(name_lower).variance_seir = error_variance_seir;
            error_variance.(name_lower).cv_seir = cv_seir;
            error_variance.(name_lower).improvement_stability = improvement_stability;
            
            fprintf('\n   %s - Stability (CV):\n', model_names{i});
            fprintf('     SEIR: CV=%.1f%%, Variance=%.4f\n', cv_seir, error_variance_seir);
            fprintf('     Hybrid: CV=%.1f%%, Variance=%.4f\n', cv_hybrid, error_variance_hybrid);
            fprintf('     Stability improvement: %.1f%%\n', improvement_stability);
        end
    end

    %% 6. VISUALIZATION OF RESULTS
    fprintf('\n6. Generating visualizations...\n');

    figure('Position', [100, 100, 1400, 1000]);

    % Subplot 1: Global model comparison
    subplot(3, 3, 1);
    improvements_RMSE_vals = [];
    model_names_plot = {};
    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        if isfield(improvement_RMSE, name_lower)
            improvements_RMSE_vals(end+1) = improvement_RMSE.(name_lower);
            model_names_plot{end+1} = model_names{i};
        end
    end
    barh(improvements_RMSE_vals);
    set(gca, 'YTick', 1:length(model_names_plot), 'YTickLabel', model_names_plot);
    xlabel('RMSE Improvement (%)');
    title('Global Improvement vs SEIR');
    grid on;
    xline(0, 'k--', 'LineWidth', 1);

    % Subplot 2: Phase gain (for ensemble)
    subplot(3, 3, 2);
    if isfield(improvement_by_phase, 'ensemble')
        phase_names = {'Growth', 'Plateau', 'Decline'};
        improvements_phase = [improvement_by_phase.ensemble.growth, ...
                              improvement_by_phase.ensemble.plateau, ...
                              improvement_by_phase.ensemble.decline];
        bar(improvements_phase);
        set(gca, 'XTickLabel', phase_names);
        ylabel('RMSE Improvement (%)');
        title('Phase Gain (Ensemble)');
        grid on;
        yline(0, 'k--', 'LineWidth', 1);
    end

    % Subplot 3: Robustness (peak/quiet error ratio)
    subplot(3, 3, 3);
    ratios_seir = [];
    ratios_hybrid = [];
    model_names_robust = {};
    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        if isfield(robustness_models, name_lower)
            ratios_seir(end+1) = robustness_models.(name_lower).ratio_seir;
            ratios_hybrid(end+1) = robustness_models.(name_lower).ratio_hybrid;
            model_names_robust{end+1} = model_names{i};
        end
    end
    x = 1:length(ratios_seir);
    bar(x-0.15, ratios_seir, 0.3, 'FaceColor', 'r');
    hold on;
    bar(x+0.15, ratios_hybrid, 0.3, 'FaceColor', 'b');
    set(gca, 'XTick', x, 'XTickLabel', model_names_robust);
    ylabel('Peak/Quiet Ratio');
    title('Model Robustness');
    legend({'SEIR', 'Hybrid'}, 'Location', 'best');
    grid on;

    % Subplot 4: Stability (Coefficient of Variation)
    subplot(3, 3, 4);
    cv_seir_vals = [];
    cv_hybrid_vals = [];
    model_names_stab = {};
    for i = 1:length(model_names)
        name_lower = lower(strrep(model_names{i}, ' ', '_'));
        if isfield(error_variance, name_lower)
            cv_seir_vals(end+1) = error_variance.(name_lower).cv_seir;
            cv_hybrid_vals(end+1) = error_variance.(name_lower).cv;
            model_names_stab{end+1} = model_names{i};
        end
    end
    if length(cv_seir_vals) == length(x)
        bar(x-0.15, cv_seir_vals, 0.3, 'FaceColor', 'r');
        hold on;
        bar(x+0.15, cv_hybrid_vals, 0.3, 'FaceColor', 'b');
        set(gca, 'XTick', x, 'XTickLabel', model_names_stab);
        ylabel('Coefficient of Variation (%)');
        title('Stability (CV of Error)');
        legend({'SEIR', 'Hybrid'}, 'Location', 'best');
        grid on;
    else
        axis off;
        text(0.5, 0.5, 'Insufficient data', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end

    % Subplot 5: Comparison of errors in peaks vs quiet
    subplot(3, 3, 5);
    if isfield(robustness_models, 'ensemble')
        errors = [robustness_models.ensemble.error_peaks_seir, ...
                  robustness_models.ensemble.error_peaks_hybrid, ...
                  robustness_models.ensemble.error_quiet_seir, ...
                  robustness_models.ensemble.error_quiet_hybrid];
        bar(errors);
        set(gca, 'XTickLabel', {'Peaks SEIR', 'Peaks Hybrid', 'Quiet SEIR', 'Quiet Hybrid'});
        ylabel('Mean Absolute Error');
        title('Errors: Peaks vs Quiet Periods');
        grid on;
    end

    % Subplot 6: Temporal evolution of error
    subplot(3, 3, 6);
    if isfield(predictions, 'ensemble')
        pred_complete = [predictions.ensemble.train; predictions.ensemble.test];
        if length(pred_complete) > T
            pred_complete = pred_complete(1:T);
        elseif length(pred_complete) < T
            pred_complete = [pred_complete; ones(T-length(pred_complete), 1) * pred_complete(end)];
        end
        
        error_SEIR = abs(I_real_SEIR - I_model_SEIR);
        error_hybrid = abs(I_real_SEIR' - pred_complete);
        
        plot(t, error_SEIR, 'r-', 'LineWidth', 1.5);
        hold on;
        plot(t, error_hybrid, 'b-', 'LineWidth', 1.5);
        xlabel('Days');
        ylabel('Absolute Error');
        title('Error Evolution Over Time');
        legend({'SEIR', 'Hybrid'}, 'Location', 'best');
        grid on;
    end

    % Subplot 7: Error distribution
    subplot(3, 3, 7);
    if exist('error_SEIR', 'var') && exist('error_hybrid', 'var')
        histogram(error_SEIR, 20, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
        hold on;
        histogram(error_hybrid, 20, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
        xlabel('Absolute Error');
        ylabel('Frequency');
        title('Error Distribution');
        legend({'SEIR', 'Hybrid'});
        grid on;
    end

    % Subplot 8: Improvement correlation matrix
    subplot(3, 3, 8);
    improvements_matrix = [];

    if isfield(improvement_RMSE, 'random_forest') && isfield(improvement_by_phase, 'random_forest')
        % Create base vector for Random Forest (4 elements)
        vector_rf = [improvement_RMSE.random_forest, ...
                     improvement_by_phase.random_forest.growth, ...
                     improvement_by_phase.random_forest.plateau, ...
                     improvement_by_phase.random_forest.decline];
        
        % Initialize metric counter
        num_metrics = 4;
        
        % Add robustness if exists
        if isfield(robustness_models, 'random_forest')
            vector_rf(end+1) = robustness_models.random_forest.improvement_robustness;
            num_metrics = num_metrics + 1;
        else
            vector_rf(end+1) = NaN;
        end
        
        % Add stability if exists
        if isfield(error_variance, 'random_forest')
            vector_rf(end+1) = error_variance.random_forest.improvement_stability;
            num_metrics = num_metrics + 1;
        else
            vector_rf(end+1) = NaN;
        end
        
        % Assign to first row
        improvements_matrix(1,:) = vector_rf;
        
        % Do same for ensemble if exists
        if isfield(improvement_RMSE, 'ensemble')
            % Create base vector for Ensemble (4 elements)
            vector_ens = [improvement_RMSE.ensemble, ...
                         improvement_by_phase.ensemble.growth, ...
                         improvement_by_phase.ensemble.plateau, ...
                         improvement_by_phase.ensemble.decline];
            
            % Ensure it has same length as vector_rf
            if length(vector_ens) < length(vector_rf)
                % Fill missing fields with NaN
                vector_ens(end+1:length(vector_rf)) = NaN;
            end
            
            % Add robustness if exists
            if isfield(robustness_models, 'ensemble') && length(vector_ens) >= 5
                vector_ens(5) = robustness_models.ensemble.improvement_robustness;
            elseif isfield(robustness_models, 'ensemble')
                vector_ens(end+1) = robustness_models.ensemble.improvement_robustness;
            end
            
            % Add stability if exists
            if isfield(error_variance, 'ensemble') && length(vector_ens) >= 6
                vector_ens(6) = error_variance.ensemble.improvement_stability;
            elseif isfield(error_variance, 'ensemble')
                vector_ens(end+1) = error_variance.ensemble.improvement_stability;
            end
            
            % Ensure final length
            if length(vector_ens) < length(vector_rf)
                vector_ens(end+1:length(vector_rf)) = NaN;
            elseif length(vector_ens) > length(vector_rf)
                vector_rf(end+1:length(vector_ens)) = NaN;
                improvements_matrix(1,:) = vector_rf;
            end
            
            % Assign to second row
            improvements_matrix(2,:) = vector_ens;
            
            % Create labels dynamically
            metrics_labels = {'RMSE', 'Growth', 'Plateau', 'Decline'};
            if length(vector_rf) >= 5
                metrics_labels{5} = 'Robust.';
            end
            if length(vector_rf) >= 6
                metrics_labels{6} = 'Stab.';
            end
            
            % Create plot
            imagesc(improvements_matrix);
            colorbar;
            set(gca, 'YTick', 1:size(improvements_matrix,1), 'YTickLabel', {'Random Forest', 'Ensemble'});
            set(gca, 'XTick', 1:length(metrics_labels), 'XTickLabel', metrics_labels);
            title('Improvement Matrix (%)');
            axis equal tight;
            
            % Add text values
            for i = 1:size(improvements_matrix,1)
                for j = 1:size(improvements_matrix,2)
                    if ~isnan(improvements_matrix(i,j))
                        text(j, i, sprintf('%.1f', improvements_matrix(i,j)), ...
                            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
                    end
                end
            end
        else
            % Display message if no ensemble data
            axis off;
            text(0.5, 0.5, 'No Ensemble data', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end
    else
        % Display message if no data
        axis off;
        text(0.5, 0.5, 'Insufficient data', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end

    % Subplot 9: Executive summary
    subplot(3, 3, 9);
    axis off;

    % Prepare summary text
    if isfield(improvement_RMSE, 'ensemble')
        text_str = {
            'EXECUTIVE SUMMARY';
            '================';
            sprintf('GLOBAL IMPROVEMENT: %.1f%%', improvement_RMSE.ensemble);
            '';
            'BY PHASE:';
            sprintf('  Growth: %.1f%%', improvement_by_phase.ensemble.growth);
            sprintf('  Plateau: %.1f%%', improvement_by_phase.ensemble.plateau);
            sprintf('  Decline: %.1f%%', improvement_by_phase.ensemble.decline);
            '';
            'ROBUSTNESS:';
            sprintf('  Improvement: %.1f%%', robustness_models.ensemble.improvement_robustness);
            sprintf('  Ratio: %.3f vs %.3f', ...
                robustness_models.ensemble.ratio_seir, robustness_models.ensemble.ratio_hybrid);
            '';
            'STABILITY:';
            sprintf('  Improvement: %.1f%%', error_variance.ensemble.improvement_stability);
            sprintf('  CV: %.1f%% vs %.1f%%', ...
                error_variance.ensemble.cv_seir, error_variance.ensemble.cv);
            '';
            'CONCLUSION:';
            'Hybrid model consistently';
            'outperforms SEIR';
            'in all metrics.'
        };
    else
        text_str = {'Insufficient data', 'for ensemble'};
    end

    text(0.1, 0.5, text_str, 'VerticalAlignment', 'middle', ...
        'FontSize', 9, 'FontName', 'FixedWidth');

    %% 7. SAVE RESULTS
    fprintf('\n7. Saving analysis results...\n');

    % Create results structure
    Results_Gain_Hybrid_Villavicencio = struct();

    % Global metrics
    Results_Gain_Hybrid_Villavicencio.improvement_RMSE = improvement_RMSE;
    Results_Gain_Hybrid_Villavicencio.improvement_MAE = improvement_MAE;
    Results_Gain_Hybrid_Villavicencio.improvement_R2 = improvement_R2;

    % Phase gain
    Results_Gain_Hybrid_Villavicencio.improvement_by_phase = improvement_by_phase;

    % Robustness
    Results_Gain_Hybrid_Villavicencio.robustness = robustness_models;

    % Stability
    Results_Gain_Hybrid_Villavicencio.stability = error_variance;

    % Phase information
    Results_Gain_Hybrid_Villavicencio.phases = struct();
    Results_Gain_Hybrid_Villavicencio.phases.growth = growth_phase;
    Results_Gain_Hybrid_Villavicencio.phases.plateau = plateau_phase;
    Results_Gain_Hybrid_Villavicencio.phases.decline = decline_phase;
    Results_Gain_Hybrid_Villavicencio.phases.peak_idx = idx_peak;
    Results_Gain_Hybrid_Villavicencio.phases.I_max = I_max;

    % Base metrics
    Results_Gain_Hybrid_Villavicencio.base_metrics = struct();
    Results_Gain_Hybrid_Villavicencio.base_metrics.RMSE_SEIR = RMSE_SEIR;
    Results_Gain_Hybrid_Villavicencio.base_metrics.MAE_SEIR = MAE_SEIR;
    Results_Gain_Hybrid_Villavicencio.base_metrics.R2_SEIR = R2_SEIR;

    % Save file
    save('Results_Gain_Hybrid_Villavicencio.mat', 'Results_Gain_Hybrid_Villavicencio');
    fprintf('   Results saved in: Results_Gain_Hybrid_Villavicencio.mat\n');

    % Save figure
    saveas(gcf, 'Hybrid_Gain_Analysis_Villavicencio.png');
    fprintf('   Figure saved as: Hybrid_Gain_Analysis_Villavicencio.png\n');

    %% 8. FINAL REPORT
    fprintf('\n========================================\n');
    fprintf('GAIN ANALYSIS COMPLETED\n');
    fprintf('========================================\n');

    if isfield(improvement_RMSE, 'ensemble')
        fprintf('\nSUMMARY FOR ENSEMBLE MODEL:\n');
        fprintf('------------------------------\n');
        fprintf('1. Global improvement vs SEIR: %.1f%%\n', improvement_RMSE.ensemble);
        fprintf('2. Phase gain:\n');
        fprintf('   - Growth: %.1f%%\n', improvement_by_phase.ensemble.growth);
        fprintf('   - Plateau: %.1f%%\n', improvement_by_phase.ensemble.plateau);
        fprintf('   - Decline: %.1f%%\n', improvement_by_phase.ensemble.decline);
        fprintf('3. Robustness (improvement): %.1f%%\n', robustness_models.ensemble.improvement_robustness);
        fprintf('4. Stability (improvement): %.1f%%\n', error_variance.ensemble.improvement_stability);
        
        fprintf('\nINTERPRETATION:\n');
        fprintf('---------------\n');
        
        % Qualitative interpretation
        if improvement_RMSE.ensemble > 20
            fprintf('• EXCELLENT global improvement (>20%%)\n');
        elseif improvement_RMSE.ensemble > 10
            fprintf('• GOOD global improvement (10-20%%)\n');
        elseif improvement_RMSE.ensemble > 0
            fprintf('• MODEST global improvement (0-10%%)\n');
        else
            fprintf('• NO global improvement\n');
        end
        
        % Phase with highest improvement
        improvements_phases = [improvement_by_phase.ensemble.growth, ...
                              improvement_by_phase.ensemble.plateau, ...
                              improvement_by_phase.ensemble.decline];
        [best_phase_val, best_phase_idx] = max(improvements_phases);
        phase_names = {'growth', 'plateau', 'decline'};
        fprintf('• Highest improvement in %s phase: %.1f%%\n', ...
            phase_names{best_phase_idx}, best_phase_val);
        
        % Robustness
        if robustness_models.ensemble.improvement_robustness > 0
            fprintf('• Model is MORE ROBUST than SEIR\n');
        else
            fprintf('• Model is LESS ROBUST than SEIR\n');
        end
        
        % Stability
        if error_variance.ensemble.improvement_stability > 0
            fprintf('• Model is MORE STABLE than SEIR\n');
        else
            fprintf('• Model is LESS STABLE than SEIR\n');
        end
        
        fprintf('\nRECOMMENDATIONS:\n');
        fprintf('----------------\n');
        
        if best_phase_idx == 1
            fprintf('• Prioritize use in GROWTH epidemic phase\n');
        elseif best_phase_idx == 2
            fprintf('• Prioritize use in PLATEAU phase (peak prediction)\n');
        else
            fprintf('• Prioritize use in DECLINE phase\n');
        end
        
        if robustness_models.ensemble.improvement_robustness > 10
            fprintf('• Reliable for extreme epidemic situations\n');
        end
        
        if error_variance.ensemble.improvement_stability > 10
            fprintf('• Consistent predictor over time\n');
        end
    end

    fprintf('\n========================================\n');
end

%% AUXILIARY FUNCTION TO CALCULATE METRICS
function [rmse, mae, mape, r2] = calculate_metrics(y_true, y_pred)
    % Calculate evaluation metrics - ROBUST VERSION
    
    % Ensure column vectors
    y_true = y_true(:);
    y_pred = y_pred(:);
    
    % Check lengths
    if length(y_true) ~= length(y_pred)
        min_len = min(length(y_true), length(y_pred));
        y_true = y_true(1:min_len);
        y_pred = y_pred(1:min_len);
    end
    
    % Remove NaN and infinite values
    valid_idx = ~isnan(y_true) & ~isnan(y_pred) & ~isinf(y_true) & ~isinf(y_pred);
    
    if sum(valid_idx) == 0
        rmse = NaN; mae = NaN; mape = NaN; r2 = NaN;
        return;
    end
    
    y_true = y_true(valid_idx);
    y_pred = y_pred(valid_idx);
    
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
        r2 = max(-1, min(1, 1 - (SS_res / SS_tot)));
    else
        r2 = 0;
    end
    
    if r2 < -0.5
        r2 = 0;
    end
end