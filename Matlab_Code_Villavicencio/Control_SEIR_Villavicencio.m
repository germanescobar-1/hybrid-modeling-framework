function Control_SEIR_Villavicencio()
    % Control_SEIR_Villavicencio: Estimates SEIR model parameters with time-varying control 
    %                              and fits to incidence data from Villavicencio, Colombia.
    %
    % INPUTS:
    %   - Requires 'Dataset_Processed_Villavicencio.mat' file containing a table 
    %     'Dataset_Processed_Villavicencio' with a column 'infectados' (incidence data).
    %   - Population size N = 553409 (hardcoded for Villavicencio).
    %
    % OUTPUTS:
    %   - Saves 'results_control_SEIR_Villavicencio.mat' with a structure containing:
    %       * I_real: Observed incidence data
    %       * I_seir: Model-predicted incidence
    %       * S_seir, E_seir: Compartment populations over time
    %       * u_opt: Optimal control intensity (daily)
    %       * beta_opt: Time-varying transmission rate (beta0*(1-u))
    %       * R0_opt: Time-varying effective reproduction number
    %       * metrics: Structure with RMSE, MAE, MAPE, R², correlation
    %   - Generates 'Control_SEIR_Villavicencio.png' with two subplots:
    %       1. Data vs. model fit with R² value
    %       2. Effective reproduction number over time
    %
    % METHOD:
    %   - Simplified SEIR model with observation delay and underreporting
    %   - Control implemented as 12-day blocks of intensity u (0 to 1)
    %   - Parameters estimated via fmincon with regularization

    % === Load data ===
    load("Results_Dataset_Villavicencio.mat");
    incidence_data = Results_Dataset_Villavicencio.infectados;
    T = height(incidence_data);
    N = 553409;  % Total population (adjust if needed)

    % === Fixed parameters based on literature ===
    sigma = 1/5;   % Incubation: 5 days
    gamma = 1/7;   % Recovery: 7 days

    % === Parameters to estimate (initial values) ===
    beta0_init = 0.34;   % Base transmission rate
    rho_init = 0.5;      % Underreporting factor
    tau_init = 5;        % Fixed delay infection -> symptoms (days)

    % Control: 12-day blocks
    control_step = 12;
    num_blocks = ceil(T / control_step);
    u0 = 0.5 * ones(num_blocks, 1);

    % Parameter vector: [beta0, rho, tau, E0, I0, u1, u2, ...]
    % Initial estimate of E0 and I0 based on first few days
    E0_init = incidence_data(1) / (rho_init * sigma) * 5;
    I0_init = incidence_data(1) / rho_init * 2;

    param0 = [beta0_init; rho_init; tau_init; E0_init; I0_init; u0];

    % Bounds
    param_lb = [0.05; 0.05; 1; 1; 1; zeros(num_blocks, 1)];
    param_ub = [1.0; 1.0; 14; N*0.1; N*0.1; ones(num_blocks, 1)];

    % Objective function
    obj = @(params) simplified_SEIR_cost(params, incidence_data, N, sigma, gamma, control_step);

    options = optimoptions('fmincon', 'Display', 'iter', 'MaxIterations', 1000);

    [params_opt, fval] = fmincon(obj, param0, [], [], [], [], param_lb, param_ub, [], options);

    % Extract results and simulate
    beta0_opt = params_opt(1);
    rho_opt = params_opt(2);
    tau_opt = round(params_opt(3));  % integer delay
    E0_opt = params_opt(4);
    I0_opt = params_opt(5);
    u_blocks_opt = params_opt(6:end);

    % Simulation
    u_daily = expand_to_days(u_blocks_opt, T, control_step);
    S0_opt = N - E0_opt - I0_opt;
    R0_init = 0;

    [S, E, I, R, Y_model] = simulate_simplified_SEIR(beta0_opt, sigma, gamma, rho_opt, tau_opt, ...
                                                      S0_opt, E0_opt, I0_opt, R0_init, N, u_daily);

    % Metrics (ADDED)
    RMSE = sqrt(mean((incidence_data' - Y_model).^2));
    MAE = mean(abs(incidence_data' - Y_model));
    MAPE = 100 * mean(abs((incidence_data' - Y_model) ./ (incidence_data' + eps)));
    
    SS_res = sum((incidence_data' - Y_model).^2);
    SS_tot = sum((incidence_data' - mean(incidence_data')).^2);
    if SS_tot > 0
        R2 = 1 - (SS_res / SS_tot);
    else
        R2 = 0;
    end
    
    data_correlation = corr(incidence_data, Y_model');

    fprintf('RMSE: %.2f, MAE: %.2f, MAPE: %.1f%%, R²: %.4f, Correlation: %.4f\n', ...
        RMSE, MAE, MAPE, R2, data_correlation);
   
    % Save results WITH METRICS
    Results_Control_SEIR_Villavicencio.I_real = incidence_data';
    Results_Control_SEIR_Villavicencio.I_seir = Y_model;
    Results_Control_SEIR_Villavicencio.S_seir = S;
    Results_Control_SEIR_Villavicencio.E_seir = E;
    Results_Control_SEIR_Villavicencio.u_opt = u_daily;
    Results_Control_SEIR_Villavicencio.beta_opt = beta0_opt*(1-u_daily);
    Results_Control_SEIR_Villavicencio.R0_opt = beta0_opt*(1-u_daily)/gamma;
    
    % ADD METRICS TO STRUCTURE
    Results_Control_SEIR_Villavicencio.metrics = struct();
    Results_Control_SEIR_Villavicencio.metrics.RMSE = RMSE;
    Results_Control_SEIR_Villavicencio.metrics.MAE = MAE;
    Results_Control_SEIR_Villavicencio.metrics.MAPE = MAPE;
    Results_Control_SEIR_Villavicencio.metrics.R2 = R2;
    Results_Control_SEIR_Villavicencio.metrics.correlation = data_correlation;

    save('Results_Control_SEIR_Villavicencio.mat', 'Results_Control_SEIR_Villavicencio');

    % Plots
    t = 1:T;
    figure;
    subplot(2,1,1);
    plot(t, incidence_data, 'r-', t, Y_model, 'b--', 'LineWidth', 2);
    legend('Data', 'Model');
    ylabel('Incidence');
    title(['Simplified SEIR fit, R^2=' num2str(R2)]);

    subplot(2,1,2);
    plot(t, beta0_opt*(1-u_daily)/gamma, 'LineWidth', 2);
    hold on; plot([1 T], [1 1], 'k--');
    ylabel('R_t'); xlabel('Days');
    title('Effective reproduction number');

    % Save plot
    saveas(figure(1), 'Control_SEIR_Villavicencio.png');
end

function J = simplified_SEIR_cost(params, Y_real, N, sigma, gamma, control_step)
    % Cost function for parameter estimation
    beta0 = params(1);
    rho = params(2);
    tau = round(params(3));  % integer delay
    E0 = params(4);
    I0 = params(5);
    u_blocks = params(6:end);

    T = length(Y_real);
    u_daily = expand_to_days(u_blocks, T, control_step);

    S0 = N - E0 - I0;
    R0 = 0;

    [~, ~, ~, ~, Y_model] = simulate_simplified_SEIR(beta0, sigma, gamma, rho, tau, ...
                                                      S0, E0, I0, R0, N, u_daily);

    % Fit error (quadratic)
    fit_error = sum((Y_real' - Y_model).^2);

    % Simple regularization for control (smoothness)
    if length(u_blocks) > 1
        u_changes = diff(u_blocks);
        penalty_changes = sum(u_changes.^2);
    else
        penalty_changes = 0;
    end

    % Penalize deviations of tau from typical values (5-6 days)
    penalty_tau = (tau - 5)^2;

    J = fit_error + 0.1*penalty_changes + 0.01*penalty_tau;
end

function [S, E, I, R, Y_obs] = simulate_simplified_SEIR(beta0, sigma, gamma, rho, tau, ...
                                                         S0, E0, I0, R0, N, u)
    % Simplified SEIR model simulation with observation delay
    T = length(u);
    S = zeros(1, T);
    E = zeros(1, T);
    I = zeros(1, T);
    R = zeros(1, T);

    S(1) = S0;
    E(1) = E0;
    I(1) = I0;
    R(1) = R0;

    % Pre-allocate modeled incidence
    Y_obs = zeros(1, T);

    for t = 1:T-1
        beta = beta0 * (1 - u(t));
        new_infections = beta * S(t) * I(t) / N;
        new_infectious = sigma * E(t);

        S(t+1) = S(t) - new_infections;
        E(t+1) = E(t) + new_infections - new_infectious;
        I(t+1) = I(t) + new_infectious - gamma * I(t);
        R(t+1) = R(t) + gamma * I(t);

        % Observed incidence is rho * new_infectious, with delay tau
        if t >= tau
            Y_obs(t) = rho * sigma * E(t - tau + 1);  % +1 for MATLAB indexing
        end
    end

    % For the last day
    if T >= tau
        Y_obs(T) = rho * sigma * E(T - tau + 1);
    end
end

function u_daily = expand_to_days(u_blocks, T, step)
    % Expand block control values to daily values
    B = length(u_blocks);
    u_daily = zeros(1, T);
    for i = 1:B
        start_idx = (i-1)*step + 1;
        end_idx = min(i*step, T);
        u_daily(start_idx:end_idx) = u_blocks(i);
    end
end
