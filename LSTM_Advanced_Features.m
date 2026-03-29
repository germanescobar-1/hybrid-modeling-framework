%% LSTM_ADVANCED_FEATURES.m - LSTM with advanced features (MODIFIED)
function [lstm_results] = LSTM_Advanced_Features(I, S, E, beta, u, R0, train_ratio)
    % LSTM_ADVANCED_FEATURES - Trains LSTM model with advanced features
    %
    % Syntax:
    %   lstm_results = LSTM_Advanced_Features(I, S, E, beta, u, R0, train_ratio)
    %
    % INPUTS:
    %   I - Vector of real infected cases
    %   S - Vector of SEIR susceptibles
    %   E - Vector of SEIR exposed
    %   beta - Vector beta(t) from optimal control
    %   u - Vector of control u(t)
    %   R0 - Vector of dynamic R0(t)
    %   train_ratio - Training proportion (0.7 for 70%)
    %
    % OUTPUTS:
    %   lstm_results - Structure with LSTM model results containing:
    %       * y_pred_train: Training predictions (aligned with input)
    %       * y_pred_test: Test predictions (aligned with input)
    %       * rmse_train, rmse_test: RMSE metrics
    %       * mae_train, mae_test: MAE metrics
    %       * mape_train, mape_test: MAPE metrics
    %       * r2_train, r2_test: R² metrics
    %       * net: Trained LSTM network
    %       * mu_X, sigma_X: Normalization parameters for features
    %       * mu_y, sigma_y: Normalization parameters for target
    %       * seq_len: Sequence length used
    %       * selected_features: Features selected for the model
    %       * train_ratio: Training ratio used

    % 1. VERIFY INPUTS
    fprintf('=== LSTM WITH ADVANCED FEATURES ===\n');

    % If train_ratio not provided, use default value
    if nargin < 7
        train_ratio = 0.7;  % 70% training by default
        fprintf('Using default train_ratio: %.1f\n', train_ratio);
    end

    % Verify dimensions
    fprintf('\n=== INPUT DATA VERIFICATION ===\n');
    fprintf('I (infected): %d×%d\n', size(I,1), size(I,2));
    fprintf('S (susceptibles): %d×%d\n', size(S,1), size(S,2));
    fprintf('E (exposed): %d×%d\n', size(E,1), size(E,2));
    fprintf('beta: %d×%d\n', size(beta,1), size(beta,2));
    fprintf('u (control): %d×%d\n', size(u,1), size(u,2));
    fprintf('R0: %d×%d\n', size(R0,1), size(R0,2));

    % 2. CREATE ADVANCED FEATURES
    fprintf('\n=== CREATING ADVANCED FEATURES ===\n');

    % Create time vector
    t = (1:length(I))';

    % Call advanced features function
    [X_adv, feature_names] = create_advanced_features(t, I, S, E, beta, u, R0);

    % 3. FEATURE SELECTION
    fprintf('\n=== FEATURE SELECTION ===\n');

    % Selected features (based on previous analysis)
    selected_features = {'MA_7', 'I_lag_7', 'E_seir', 'beta', 'u', 'R0', 'dI_abs', 'I_exp_smooth', 'MA_3'};

    selected_idx = [];
    for i = 1:length(selected_features)
        idx = find(strcmp(feature_names, selected_features{i}));
        if ~isempty(idx)
            selected_idx = [selected_idx, idx];
            fprintf('✓ Selected feature: %s (index %d)\n', selected_features{i}, idx);
        else
            fprintf('✗ Feature not found: %s\n', selected_features{i});
        end
    end

    % Select only important features
    X_selected = X_adv(:, selected_idx);
    feature_names_selected = feature_names(selected_idx);

    fprintf('\nFinal selected features (%d):\n', length(selected_idx));
    for i = 1:length(feature_names_selected)
        fprintf('  %2d. %s\n', i, feature_names_selected{i});
    end

    % 4. TRAIN/TEST SPLIT (using provided train_ratio)
    n = size(X_selected, 1);
    train_idx = floor(train_ratio * n);
    num_features = size(X_selected, 2);

    X_train = X_selected(1:train_idx, :);
    X_test = X_selected(train_idx+1:end, :);
    y_train = I(1:train_idx);
    y_test = I(train_idx+1:end);

    fprintf('\n=== DATA SPLIT ===\n');
    fprintf('Total samples: %d\n', n);
    fprintf('Train: %d (%.1f%%)\n', train_idx, train_ratio*100);
    fprintf('Test:  %d (%.1f%%)\n', n-train_idx, (1-train_ratio)*100);
    fprintf('Number of features: %d\n', num_features);

    % 5. NORMALIZE
    fprintf('\n=== NORMALIZING DATA ===\n');

    [X_train_norm, mu_X, sigma_X] = zscore(X_train);
    X_test_norm = (X_test - mu_X) ./ sigma_X;
    [y_train_norm, mu_y, sigma_y] = zscore(y_train);
    y_test_norm = (y_test - mu_y) ./ sigma_y;

    fprintf('Normalization completed.\n');

    % 6. CREATE SEQUENCES WITH CELL ARRAYS
    seq_len = 7;  % Use 7 days to capture weekly cycles

    fprintf('\n=== CREATING SEQUENCES WITH CELL ARRAYS ===\n');

    n_train_seq = size(X_train_norm, 1) - seq_len;
    n_test_seq = size(X_test_norm, 1) - seq_len;

    fprintf('Training sequences: %d\n', n_train_seq);
    fprintf('Test sequences: %d\n', n_test_seq);

    % Initialize cell arrays for training
    X_train_cell = cell(n_train_seq, 1);
    y_train_seq = zeros(n_train_seq, 1);

    % Initialize cell arrays for test
    X_test_cell = cell(n_test_seq, 1);
    y_test_seq_norm = zeros(n_test_seq, 1);

    % Fill cell arrays for training
    fprintf('Creating training sequences...\n');
    for i = 1:n_train_seq
        % Extract 7-day sequence
        seq = X_train_norm(i:i+seq_len-1, :);  % [7 × num_features]
        % Transpose to format [numFeatures × sequenceLength]
        X_train_cell{i} = seq';  % [num_features × 7]
        % Target is the value on the day after the sequence
        y_train_seq(i) = y_train_norm(i + seq_len);

        if mod(i, 100) == 0 && i <= n_train_seq
            fprintf('  Processed %d/%d sequences...\n', i, n_train_seq);
        end
    end

    % Fill cell arrays for test
    fprintf('Creating test sequences...\n');
    for i = 1:n_test_seq
        % Test sequence
        seq = X_test_norm(i:i+seq_len-1, :);  % [7 × num_features]
        X_test_cell{i} = seq';  % [num_features × 7]
        % Target is the value on the day after the sequence
        y_test_seq_norm(i) = y_test_norm(i + seq_len);

        if mod(i, 100) == 0 && i <= n_test_seq
            fprintf('  Processed %d/%d sequences...\n', i, n_test_seq);
        end
    end

    fprintf('\n=== FINAL VERIFICATION ===\n');
    fprintf('X_train_cell: cell array of %d elements\n', length(X_train_cell));
    fprintf('Each cell: %s (features × days)\n', mat2str(size(X_train_cell{1})));
    fprintf('y_train_seq: %s\n', mat2str(size(y_train_seq)));

    % 7. IMPROVED LSTM NETWORK CONFIGURATION
    fprintf('\n=== CONFIGURING IMPROVED LSTM ===\n');

    % Increase network capacity to handle more features
    layers = [
        sequenceInputLayer(num_features, 'Name', 'input')
        
        % First LSTM layer with more units (30)
        lstmLayer(30, 'Name', 'lstm1', 'OutputMode', 'sequence')
        
        % Dropout for regularization
        dropoutLayer(0.2, 'Name', 'dropout1')
        
        % Second LSTM layer (10)
        lstmLayer(10, 'Name', 'lstm2', 'OutputMode', 'last')
        
        % Additional dropout
        dropoutLayer(0.2, 'Name', 'dropout2')
        
        % Fully connected layers (20) (10) (1)
        fullyConnectedLayer(20, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        
        fullyConnectedLayer(10, 'Name', 'fc2')
        reluLayer('Name', 'relu2')
        
        fullyConnectedLayer(1, 'Name', 'fc3')
        
        regressionLayer('Name', 'output')
    ];

    % Improved training options
    options = trainingOptions('adam', ...
        'MaxEpochs', 150, ...           % Fewer epochs for integration
        'MiniBatchSize', 32, ...        % Optimal batch size
        'InitialLearnRate', 0.01, ...   % Learning rate
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropFactor', 0.5, ...
        'LearnRateDropPeriod', 40, ...
        'L2Regularization', 0.01, ...   % L2 regularization
        'GradientThreshold', 1, ...      % For training stability
        'Verbose', 0, ...                % Less verbose for integration
        'Plots', 'none', ...              % No training plot
        'ValidationData', {X_test_cell, y_test_seq_norm}, ...  % Validation during training
        'ValidationFrequency', 10, ...
        'ExecutionEnvironment', 'auto');

    % 8. TRAIN LSTM
    fprintf('\n=== TRAINING LSTM WITH ADVANCED FEATURES ===\n');

    net = trainNetwork(X_train_cell, y_train_seq, layers, options);
    fprintf('✅ LSTM TRAINED SUCCESSFULLY\n');

    % 9. PREDICTIONS
    fprintf('\n=== MAKING PREDICTIONS ===\n');

    % Predict
    y_pred_train_norm_cell = predict(net, X_train_cell);
    y_pred_train_norm = convert_predict_output(y_pred_train_norm_cell);

    y_pred_test_norm_cell = predict(net, X_test_cell);
    y_pred_test_norm = convert_predict_output(y_pred_test_norm_cell);

    % Ensure column vectors
    y_pred_train_norm = y_pred_train_norm(:);
    y_pred_test_norm = y_pred_test_norm(:);

    % Denormalize predictions
    y_pred_train = y_pred_train_norm * sigma_y + mu_y;
    y_pred_test = y_pred_test_norm * sigma_y + mu_y;

    % Real targets denormalized
    y_train_seq_actual = y_train_norm(seq_len+1:seq_len+n_train_seq) * sigma_y + mu_y;
    y_test_seq_actual = y_test_seq_norm * sigma_y + mu_y;

    % 10. COMPLETE EVALUATION
    fprintf('\n=== MODEL EVALUATION ===\n');

    % Error metrics
    rmse_train = sqrt(mean((y_pred_train - y_train_seq_actual).^2));
    rmse_test = sqrt(mean((y_pred_test - y_test_seq_actual).^2));

    mae_train = mean(abs(y_pred_train - y_train_seq_actual));
    mae_test = mean(abs(y_pred_test - y_test_seq_actual));

    mape_train = mean(abs((y_pred_train - y_train_seq_actual) ./ (y_train_seq_actual + eps))) * 100;
    mape_test = mean(abs((y_pred_test - y_test_seq_actual) ./ (y_test_seq_actual + eps))) * 100;

    % R² score
    SS_res_train = sum((y_train_seq_actual - y_pred_train).^2);
    SS_tot_train = sum((y_train_seq_actual - mean(y_train_seq_actual)).^2);
    r2_train = 1 - (SS_res_train / SS_tot_train);

    SS_res_test = sum((y_test_seq_actual - y_pred_test).^2);
    SS_tot_test = sum((y_test_seq_actual - mean(y_test_seq_actual)).^2);
    r2_test = 1 - (SS_res_test / SS_tot_test);

    fprintf('\n=== LSTM RESULTS ===\n');
    fprintf('TRAINING: RMSE=%.2f, MAE=%.2f, MAPE=%.1f%%, R²=%.4f\n', ...
        rmse_train, mae_train, mape_train, r2_train);
    fprintf('TESTING:  RMSE=%.2f, MAE=%.2f, MAPE=%.1f%%, R²=%.4f\n', ...
        rmse_test, mae_test, mape_test, r2_test);

    % 11. PREPARE RESULTS FOR RETURN
    fprintf('\n=== PREPARING RESULTS FOR INTEGRATION ===\n');

    % Create full prediction vectors (same length as y_train, y_test)
    y_pred_lstm_train_full = zeros(length(y_train), 1);
    y_pred_lstm_test_full = zeros(length(y_test), 1);

    % ===== CRITICAL CORRECTION: CORRECTLY ALIGN PREDICTIONS =====
    % LSTM predictions start at day seq_len+1
    % For training: indices seq_len+1 to train_idx
    train_valid_start = seq_len + 1;
    train_valid_end = seq_len + n_train_seq;

    % For test: indices seq_len+1 to n_test_seq (within test set)
    test_valid_start = seq_len + 1;
    test_valid_end = seq_len + n_test_seq;

    % Assign predictions to their correct positions
    y_pred_lstm_train_full(train_valid_start:train_valid_end) = y_pred_train;
    y_pred_lstm_test_full(test_valid_start:test_valid_end) = y_pred_test;

    % Fill missing values with more intelligent approach
    % For training: use simple linear regression for first days
    if train_valid_start > 1
        % Calculate trend from first valid predictions
        if length(y_pred_train) >= 5
            % Use first 5 values to estimate trend
            x_fit = (1:5)';
            y_fit = y_pred_train(1:5);
            p = polyfit(x_fit, y_fit, 1);
            
            % Extrapolate backwards
            for i = 1:train_valid_start-1
                y_pred_lstm_train_full(i) = polyval(p, i - train_valid_start + 1);
            end
        else
            % If insufficient data, use first predicted value
            y_pred_lstm_train_full(1:train_valid_start-1) = y_pred_train(1);
        end
    end

    % For test: same approach
    if test_valid_start > 1
        if length(y_pred_test) >= 5
            x_fit = (1:5)';
            y_fit = y_pred_test(1:5);
            p = polyfit(x_fit, y_fit, 1);
            
            for i = 1:test_valid_start-1
                y_pred_lstm_test_full(i) = polyval(p, i - test_valid_start + 1);
            end
        else
            y_pred_lstm_test_full(1:test_valid_start-1) = y_pred_test(1);
        end
    end

    % Ensure non-negative values
    y_pred_lstm_train_full(y_pred_lstm_train_full < 0) = 0;
    y_pred_lstm_test_full(y_pred_lstm_test_full < 0) = 0;

    fprintf('Correction applied:\n');
    fprintf('  Train: %d values, of which %d are extrapolated\n', ...
        length(y_pred_lstm_train_full), train_valid_start-1);
    fprintf('  Test:  %d values, of which %d are extrapolated\n', ...
        length(y_pred_lstm_test_full), test_valid_start-1);

    % Create results structure
    lstm_results = struct();
    lstm_results.y_pred_train = y_pred_lstm_train_full;
    lstm_results.y_pred_test = y_pred_lstm_test_full;
    lstm_results.rmse_train = rmse_train;
    lstm_results.rmse_test = rmse_test;
    lstm_results.mae_train = mae_train;
    lstm_results.mae_test = mae_test;
    lstm_results.mape_train = mape_train;
    lstm_results.mape_test = mape_test;
    lstm_results.r2_train = r2_train;
    lstm_results.r2_test = r2_test;
    lstm_results.net = net;
    lstm_results.mu_X = mu_X;
    lstm_results.sigma_X = sigma_X;
    lstm_results.mu_y = mu_y;
    lstm_results.sigma_y = sigma_y;
    lstm_results.seq_len = seq_len;
    lstm_results.selected_features = selected_features;
    lstm_results.train_ratio = train_ratio;

    fprintf('LSTM results prepared for integration\n');
    fprintf('Dimensions: y_pred_train=%d, y_pred_test=%d\n', ...
        length(y_pred_lstm_train_full), length(y_pred_lstm_test_full));

end

%% Auxiliary function to convert predict outputs
function vec = convert_predict_output(pred_output)
    if iscell(pred_output)
        if iscell(pred_output{1})
            % Case: cell array of cell arrays
            vec = zeros(length(pred_output), 1);
            for i = 1:length(pred_output)
                vec(i) = double(pred_output{i}{1});
            end
        else
            % Case: cell array of numeric arrays
            try
                vec = cell2mat(pred_output);
            catch
                % If cell2mat fails, extract manually
                vec = zeros(length(pred_output), 1);
                for i = 1:length(pred_output)
                    if isscalar(pred_output{i})
                        vec(i) = pred_output{i};
                    else
                        vec(i) = pred_output{i}(1);
                    end
                end
            end
        end
    else
        % If not cell array, use directly
        vec = pred_output(:);
    end
end

%% Function to create advanced features
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