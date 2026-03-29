%% ============================================================
% CONTROL EFFICACY ANALYSIS
% Efficiency metrics according to specifications 1-6
% ============================================================

function Analysis_Efficacy_Control_Villavicencio()
    % Analysis_Efficacy_Control_Villavicencio: Analyzes control efficacy from SEIR model
    %                                           with optimal control for Villavicencio.
    %
    % INPUTS:
    %   - Requires 'results_control_SEIR_Villavicencio.mat' file containing structure
    %     with fields: I_real, I_seir, u_opt, R0_opt, beta_opt
    %
    % OUTPUTS:
    %   - Saves 'Results_Efficacy_Control_Villavicencio.mat' with all efficacy metrics
    %   - Generates 'Efficacy_Analysis_Control_Villavicencio.png' with 9 subplots
    %   - Generates 'Weight_Sensitivity.png' with weight sensitivity analysis
    %   - Prints comprehensive report with interpretation and recommendations
    %
    % METRICS CALCULATED:
    %   1. Total control load: C = ∫u(t)dt
    %   2. Control efficiency: η = (I_max_real - I_max_model)/C
    %   3. Days with R₀ < 1 and percentage
    %   4. Peak control: u_max
    %   5. Control inertia: temporal variation of u
    %   6. Cost-benefit: J = ∫(w₁·I² + w₂·u²)dt

    clear; close all; clc;
    fprintf('=== CONTROL EFFICACY ANALYSIS ===\n');

    %% 1. LOAD CONTROL MODEL DATA
    fprintf('\n1. Loading SEIR control model data...\n');
    load('Results_Control_SEIR_Villavicencio.mat');

    % Extract necessary variables
    I_real = Results_Control_SEIR_Villavicencio.I_real;
    I_model = Results_Control_SEIR_Villavicencio.I_seir;
    u_opt = Results_Control_SEIR_Villavicencio.u_opt;
    R0_t = Results_Control_SEIR_Villavicencio.R0_opt;
    beta_t = Results_Control_SEIR_Villavicencio.beta_opt;

    T = length(I_real);
    t = 1:T;

    %% 2. EFFICACY METRICS CALCULATION
    fprintf('\n2. Calculating efficacy metrics...\n');

    % 1. TOTAL CONTROL LOAD
    C = trapz(t, u_opt);  % Integral of u(t) dt
    fprintf('   Total control load: C = %.2f\n', C);

    % 2. CONTROL EFFICIENCY
    I_max_real = max(I_real);
    I_max_model = max(I_model);
    if C > 0
        eta = (I_max_real - I_max_model) / C;
    else
        eta = 0;
    end
    fprintf('   Control efficiency: η = %.4f\n', eta);
    fprintf('     I_max_real = %.0f, I_max_model = %.0f\n', I_max_real, I_max_model);

    % 3. DAYS WITH R₀ < 1
    days_R0_less_1 = sum(R0_t < 1);
    percentage_controlled = 100 * days_R0_less_1 / T;
    fprintf('   Days with R₀ < 1: %d/%d (%.1f%%)\n', days_R0_less_1, T, percentage_controlled);

    % 4. CONTROL PEAK
    u_max = max(u_opt);
    fprintf('   Control peak: u_max = %.4f\n', u_max);

    % 5. CONTROL INERTIA (temporal variation)
    if T > 1
        delta_u = diff(u_opt);
        delta_t = diff(t);
        mean_inertia = mean(abs(delta_u ./ delta_t));
        max_inertia = max(abs(delta_u ./ delta_t));
        std_inertia = std(abs(delta_u ./ delta_t));
    else
        mean_inertia = 0;
        max_inertia = 0;
        std_inertia = 0;
    end
    fprintf('   Control inertia:\n');
    fprintf('     Mean: %.4f, Max: %.4f, Std. Dev: %.4f\n', mean_inertia, max_inertia, std_inertia);

    % 6. COST-BENEFIT (cost functional)
    % Weights - adjust according to priorities
    w1 = 1.0;  % Weight for infected
    w2 = 0.5;  % Weight for control

    J = trapz(t, w1 * I_model.^2 + w2 * u_opt.^2);
    fprintf('   Cost-benefit (J): %.2e\n', J);
    fprintf('     (w1=%.2f, w2=%.2f)\n', w1, w2);

    %% 3. ADDITIONAL ANALYSIS (optional)
    fprintf('\n3. Additional analysis...\n');

    % Time to peak
    [~, idx_peak_real] = max(I_real);
    [~, idx_peak_model] = max(I_model);
    fprintf('   Peak day - Real: %d, Model: %d\n', idx_peak_real, idx_peak_model);

    % Peak percentage reduction
    peak_reduction = 100 * (I_max_real - I_max_model) / I_max_real;
    fprintf('   Peak reduction: %.1f%%\n', peak_reduction);

    % Control efficacy in different phases
    phases = floor(T/3);
    if phases >= 3
        fprintf('\n   Efficacy by phase:\n');
        for phase = 1:3
            start_idx = (phase-1)*phases + 1;
            end_idx = min(phase*phases, T);
            C_phase = trapz(t(start_idx:end_idx), u_opt(start_idx:end_idx));
            reduction_phase = mean(I_real(start_idx:end_idx) - I_model(start_idx:end_idx));
            if C_phase > 0
                eta_phase = reduction_phase / C_phase;
            else
                eta_phase = 0;
            end
            fprintf('     Phase %d (days %d-%d): η = %.4f\n', ...
                phase, start_idx, end_idx, eta_phase);
        end
    end

    %% 4. VISUALIZATION OF RESULTS
    fprintf('\n4. Generating visualizations...\n');

    figure('Position', [100, 100, 1400, 900]);

    % Subplot 1: Comparison of real vs model infected
    subplot(3, 3, 1);
    plot(t, I_real, 'r-', 'LineWidth', 2, 'DisplayName', 'Real');
    hold on;
    plot(t, I_model, 'b--', 'LineWidth', 2, 'DisplayName', 'Model');
    plot([idx_peak_real, idx_peak_real], [0, I_max_real], 'r:', 'LineWidth', 1);
    plot([idx_peak_model, idx_peak_model], [0, I_max_model], 'b:', 'LineWidth', 1);
    xlabel('Days');
    ylabel('Infected');
    title(sprintf('Infected Comparison\nPeak reduction: %.1f%%', peak_reduction));
    legend('Location', 'best');
    grid on;

    % Subplot 2: Optimal control u(t)
    subplot(3, 3, 2);
    plot(t, u_opt, 'g-', 'LineWidth', 2);
    hold on;
    fill(t, u_opt, 'g', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xlabel('Days');
    ylabel('Control u(t)');
    title(sprintf('Control Effort\nTotal load: C = %.1f, u_{max} = %.3f', C, u_max));
    grid on;

    % Subplot 3: Cumulative efficiency
    subplot(3, 3, 3);
    I_diff = I_real - I_model;
    C_cum = cumtrapz(t, u_opt);
    if C_cum(end) > 0
        eta_cum = I_diff ./ (C_cum + eps);
    else
        eta_cum = zeros(size(t));
    end
    plot(t, eta_cum, 'm-', 'LineWidth', 2);
    xlabel('Days');
    ylabel('η(t)');
    title('Instantaneous Control Efficiency');
    grid on;

    % Subplot 4: Effective R₀
    subplot(3, 3, 4);
    plot(t, R0_t, 'k-', 'LineWidth', 2);
    hold on;
    plot([1, T], [1, 1], 'r--', 'LineWidth', 1.5);
    fill([1, T, T, 1], [1, 1, 0, 0], 'r', 'FaceAlpha', 0.05, 'EdgeColor', 'none');
    xlabel('Days');
    ylabel('Effective R₀');
    title(sprintf('Effective Reproduction Number\nDays with R₀ < 1: %.1f%%', percentage_controlled));
    grid on;

    % Subplot 5: Control inertia (derivative)
    subplot(3, 3, 5);
    if T > 1
        du_dt = gradient(u_opt, t);
        plot(t, du_dt, 'c-', 'LineWidth', 2);
        hold on;
        plot([1, T], [0, 0], 'k--', 'LineWidth', 0.5);
        xlabel('Days');
        ylabel('Δu/Δt');
        title(sprintf('Control Inertia\nMean: %.4f, Max: %.4f', mean_inertia, max_inertia));
        grid on;
    else
        text(0.5, 0.5, 'Insufficient data', 'HorizontalAlignment', 'center');
    end

    % Subplot 6: Cost-benefit by component
    subplot(3, 3, 6);
    cost_infected = w1 * I_model.^2;
    cost_control = w2 * u_opt.^2;
    area(t, [cost_infected; cost_control]', 'LineStyle', 'none');
    xlabel('Days');
    ylabel('Cost');
    title(sprintf('Cost-Benefit: J = %.2e\nw₁=%.1f, w₂=%.1f', J, w1, w2));
    legend('w₁·I²(t)', 'w₂·u²(t)', 'Location', 'best');
    grid on;

    % Subplot 7: Control-Reduction relationship
    subplot(3, 3, 7);
    scatter(u_opt, I_diff, 30, t, 'filled');
    xlabel('Control u(t)');
    ylabel('Reduction I_{real} - I_{model}');
    title('Control vs Reduction Relationship');
    colorbar;
    grid on;

    % Subplot 8: Control distribution
    subplot(3, 3, 8);
    histogram(u_opt, 20, 'FaceColor', 'g', 'FaceAlpha', 0.7);
    xlabel('Control value u(t)');
    ylabel('Frequency');
    title('Control Effort Distribution');
    grid on;

    % Subplot 9: Metrics summary
    subplot(3, 3, 9);
    axis off;
    text_str = {
        sprintf('EFFICACY SUMMARY'),
        sprintf('========================'),
        sprintf('Total load: C = %.1f', C),
        sprintf('Efficiency: η = %.4f', eta),
        sprintf('R₀ < 1: %.1f%%', percentage_controlled),
        sprintf('Control peak: u_{max} = %.3f', u_max),
        sprintf('Mean inertia: %.4f', mean_inertia),
        sprintf('Cost-benefit: J = %.2e', J),
        sprintf('Peak reduction: %.1f%%', peak_reduction),
        sprintf('Analysis days: %d', T)
    };
    text(0.1, 0.5, text_str, 'VerticalAlignment', 'middle', ...
        'FontSize', 10, 'FontName', 'FixedWidth');

    %% 5. SAVE RESULTS
    fprintf('\n5. Saving results...\n');

    % Create results structure
    Results_Efficacy_Control_Villavicencio = struct();
    Results_Efficacy_Control_Villavicencio.metrics = struct();

    % Main metrics
    Results_Efficacy_Control_Villavicencio.metrics.C = C;
    Results_Efficacy_Control_Villavicencio.metrics.eta = eta;
    Results_Efficacy_Control_Villavicencio.metrics.percentage_R0_less_1 = percentage_controlled;
    Results_Efficacy_Control_Villavicencio.metrics.u_max = u_max;
    Results_Efficacy_Control_Villavicencio.metrics.mean_inertia = mean_inertia;
    Results_Efficacy_Control_Villavicencio.metrics.max_inertia = max_inertia;
    Results_Efficacy_Control_Villavicencio.metrics.std_inertia = std_inertia;
    Results_Efficacy_Control_Villavicencio.metrics.J = J;
    Results_Efficacy_Control_Villavicencio.metrics.w1 = w1;
    Results_Efficacy_Control_Villavicencio.metrics.w2 = w2;

    % Additional metrics
    Results_Efficacy_Control_Villavicencio.metrics.I_max_real = I_max_real;
    Results_Efficacy_Control_Villavicencio.metrics.I_max_model = I_max_model;
    Results_Efficacy_Control_Villavicencio.metrics.peak_reduction = peak_reduction;
    Results_Efficacy_Control_Villavicencio.metrics.days_R0_less_1 = days_R0_less_1;
    Results_Efficacy_Control_Villavicencio.metrics.total_days = T;

    % Time vectors
    Results_Efficacy_Control_Villavicencio.t = t;
    Results_Efficacy_Control_Villavicencio.I_real = I_real;
    Results_Efficacy_Control_Villavicencio.I_model = I_model;
    Results_Efficacy_Control_Villavicencio.u_opt = u_opt;
    Results_Efficacy_Control_Villavicencio.R0_t = R0_t;
    Results_Efficacy_Control_Villavicencio.eta_cum = eta_cum;

    % Save to file
    save('Results_Efficacy_Control_Villavicencio.mat', 'Results_Efficacy_Control_Villavicencio');
    fprintf('   Results saved in: Results_Efficacy_Control_Villavicencio.mat\n');

    % Save figure
    saveas(gcf, 'Efficacy_Analysis_Control_Villavicencio.png');
    fprintf('   Figure saved as: Efficacy_Analysis_Control_Villavicencio.png\n');

    %% 6. WEIGHT SENSITIVITY ANALYSIS (optional)
    fprintf('\n6. Weight sensitivity analysis w1, w2...\n');

    w1_range = [0.1, 0.5, 1.0, 2.0, 5.0];
    w2_range = [0.1, 0.5, 1.0, 2.0, 5.0];

    sensitivity = zeros(length(w1_range), length(w2_range));

    fprintf('\n   J(w1,w2) sensitivity matrix:\n');
    fprintf('   w2\\w1 ');
    fprintf('%6.1f ', w1_range);
    fprintf('\n');

    for i = 1:length(w1_range)
        for j = 1:length(w2_range)
            J_ij = trapz(t, w1_range(i) * I_model.^2 + w2_range(j) * u_opt.^2);
            sensitivity(i, j) = J_ij;
        end
    end

    % Display matrix
    for j = 1:length(w2_range)
        fprintf('   %4.1f  ', w2_range(j));
        for i = 1:length(w1_range)
            fprintf('%8.2e ', sensitivity(i, j));
        end
        fprintf('\n');
    end

    % Sensitivity figure
    figure('Position', [100, 100, 800, 600]);
    [W1, W2] = meshgrid(w1_range, w2_range);
    surf(W1, W2, sensitivity');
    xlabel('w₁ (infected weight)');
    ylabel('w₂ (control weight)');
    zlabel('J(w₁,w₂)');
    title('Cost-Benefit Sensitivity to Weights');
    grid on;
    colorbar;
    saveas(gcf, 'Weight_Sensitivity.png');

    %% 7. FINAL REPORT
    fprintf('\n========================================\n');
    fprintf('EFFICACY ANALYSIS COMPLETED\n');
    fprintf('========================================\n');
    fprintf('\nMAIN METRICS:\n');
    fprintf('-------------------\n');
    fprintf('1. Total control load: C = %.2f\n', C);
    fprintf('2. Control efficiency: η = %.4f\n', eta);
    fprintf('3. %% time with R₀ < 1: %.1f%%\n', percentage_controlled);
    fprintf('4. Control peak: u_max = %.4f\n', u_max);
    fprintf('5. Mean inertia: Δu/Δt = %.4f\n', mean_inertia);
    fprintf('6. Cost-benefit: J = %.2e\n', J);

    fprintf('\nINTERPRETATION:\n');
    fprintf('---------------\n');
    if eta > 0
        fprintf('• EFFECTIVE control (η > 0): each control unit reduces %.4f infected\n', eta);
    else
        fprintf('• INEFFECTIVE control (η ≤ 0): reconsider strategy\n');
    end

    if percentage_controlled > 50
        fprintf('• SUSTAINABLE control (R₀<1 more than 50%% of the time)\n');
    else
        fprintf('• INSUFFICIENT control (needs more effort)\n');
    end

    if u_max < 0.7
        fprintf('• REALISTIC control (u_max < 70%%)\n');
    else
        fprintf('• DEMANDING control (u_max ≥ 70%%, may be difficult to implement)\n');
    end

    fprintf('\nRECOMMENDATIONS:\n');
    fprintf('----------------\n');
    if mean_inertia > 0.05
        fprintf('• Reduce control variability (high inertia)\n');
    end
    if C > 100
        fprintf('• Consider economic cost (high total load)\n');
    end
    if peak_reduction < 30
        fprintf('• Improve effectiveness to reduce epidemic peak\n');
    end

    fprintf('\n========================================\n');
end