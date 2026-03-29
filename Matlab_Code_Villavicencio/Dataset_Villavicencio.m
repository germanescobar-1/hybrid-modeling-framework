function Results_Dataset_Villavicencio = Dataset_Villavicencio()
    % Dataset_Villavicencio: Processes raw epidemiological data from Villavicencio,
    %                         imputes missing values, and creates SEIR-ready dataset.
    %
    % INPUTS:
    %   - Requires 'RawData_Villavicencio.xlsx' file with raw case data
    %   - File should contain columns: Fecha_Notificacion, Fecha_Inicio_Sintomas,
    %     Fecha_Muerte, Fecha_Diagnostico, Fecha_Recuperacion
    %
    % OUTPUTS:
    %   - Returns table 'Dataset_Processed_Villavicencio' with fields:
    %       * fecha: Date
    %       * expuestos: Daily exposed cases
    %       * infectados: Daily infected cases
    %       * recuperados: Daily recovered cases
    %       * muertos: Daily deaths
    %       * infectados_activos: Active infected cases
    %   - Saves 'Dataset_Processed_Villavicencio.mat' with the processed data
    %   - Saves 'Dataset_Processed_Villavicencio.xlsx' with the processed data
    %   - Saves 'imputation_statistics_villavicencio.mat' with imputation statistics
    %   - Saves 'imputation_report_villavicencio.txt' with detailed imputation report
    %   - Generates two figures with epidemiological dynamics
    %
    % METHOD:
    %   - Imputes missing symptom start dates using diagnosis or notification dates
    %   - Corrects inconsistent recovery dates (too early, too late)
    %   - Imputes missing recovery dates using lognormal distribution
    %   - Calculates SEIR compartment counts based on epidemiological parameters

    % Epidemiological parameters (COVID-19)
    avg_incubation = 5;  % days
    presymptomatic_period = 2;  % days before symptoms when infectious
    infection_duration = 14;  % days of infectiousness (increased for safety)
    total_population = 553409;  % Total population of Villavicencio
    
    % Imputation parameters
    avg_recovery_days = 14;  % Average recovery days
    avg_mortality_days = 21;  % Average mortality days (if applicable)
    
    % 1. Read Excel file
    filename = 'RawData_Villavicencio.xlsx';
    data = readtable(filename);
    
    % Convert date columns to datetime
    date_vars = {'Fecha_Notificacion', 'Fecha_Inicio_Sintomas', 'Fecha_Muerte', ...
                 'Fecha_Diagnostico', 'Fecha_Recuperacion'};
    
    fprintf('Processing %d records...\n', height(data));
    
    for i = 1:length(date_vars)
        if ismember(date_vars{i}, data.Properties.VariableNames)
            data.(date_vars{i}) = datetime(data.(date_vars{i}), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        end
    end
    
    % 2. DATA VALIDATION AND CLEANING
    fprintf('\n=== DATA VALIDATION ===\n');
    
    % a) Check missing dates
    n_missing_symptom_date = sum(isnat(data.Fecha_Inicio_Sintomas));
    n_missing_recovery_date = sum(isnat(data.Fecha_Recuperacion));
    n_missing_death_date = sum(isnat(data.Fecha_Muerte));
    
    fprintf('Missing data:\n');
    fprintf('- Symptom start date: %d (%.1f%%)\n', n_missing_symptom_date, n_missing_symptom_date/height(data)*100);
    fprintf('- Recovery date: %d (%.1f%%)\n', n_missing_recovery_date, n_missing_recovery_date/height(data)*100);
    fprintf('- Death date: %d (%.1f%%)\n', n_missing_death_date, n_missing_death_date/height(data)*100);
    
    % b) Impute missing symptom start dates
    % Use diagnosis date minus 3 days (average symptoms-diagnosis)
    idx_missing_sympt = isnat(data.Fecha_Inicio_Sintomas) & ~isnat(data.Fecha_Diagnostico);
    data.Fecha_Inicio_Sintomas(idx_missing_sympt) = data.Fecha_Diagnostico(idx_missing_sympt) - days(3);
    
    % If still missing, use notification date minus 5 days
    idx_missing_sympt2 = isnat(data.Fecha_Inicio_Sintomas) & ~isnat(data.Fecha_Notificacion);
    data.Fecha_Inicio_Sintomas(idx_missing_sympt2) = data.Fecha_Notificacion(idx_missing_sympt2) - days(5);
    
    % c) Detect and correct inconsistent recovery dates
    % Case 1: Recovery before symptom start (ERROR)
    idx_rec_before_sympt = ~isnat(data.Fecha_Recuperacion) & ~isnat(data.Fecha_Inicio_Sintomas) & ...
                         (data.Fecha_Recuperacion < data.Fecha_Inicio_Sintomas);
    n_rec_before_sympt = sum(idx_rec_before_sympt);
    fprintf('- Recovery before symptoms: %d cases\n', n_rec_before_sympt);
    
    % Impute: recovery = symptoms + average days
    if any(idx_rec_before_sympt)
        data.Fecha_Recuperacion(idx_rec_before_sympt) = data.Fecha_Inicio_Sintomas(idx_rec_before_sympt) + days(avg_recovery_days);
    end
    
    % Case 2: Very early recovery (< 7 days from symptoms)
    idx_rec_very_early = ~isnat(data.Fecha_Recuperacion) & ~isnat(data.Fecha_Inicio_Sintomas) & ...
                           (days(data.Fecha_Recuperacion - data.Fecha_Inicio_Sintomas) < 7);
    n_rec_early = sum(idx_rec_very_early);
    fprintf('- Very early recovery (<7 days): %d cases\n', n_rec_early);
    
    % Impute: use lognormal distribution for mild cases
    if any(idx_rec_very_early)
        % Assign recovery between 7 and 14 days
        random_days = 7 + randn(sum(idx_rec_very_early), 1) * 2;
        random_days(random_days < 7) = 7;
        data.Fecha_Recuperacion(idx_rec_very_early) = ...
            data.Fecha_Inicio_Sintomas(idx_rec_very_early) + days(random_days);
    end
    
    % Case 3: Very late recovery (> 60 days from symptoms)
    idx_rec_very_late = ~isnat(data.Fecha_Recuperacion) & ~isnat(data.Fecha_Inicio_Sintomas) & ...
                         (days(data.Fecha_Recuperacion - data.Fecha_Inicio_Sintomas) > 60);
    n_rec_late = sum(idx_rec_very_late);
    fprintf('- Very late recovery (>60 days): %d cases\n', n_rec_late);
    
    % Impute: use maximum 45 days
    if any(idx_rec_very_late)
        data.Fecha_Recuperacion(idx_rec_very_late) = ...
            data.Fecha_Inicio_Sintomas(idx_rec_very_late) + days(45);
    end
    
    % d) Impute missing recovery dates
    % Only for cases that do NOT have a death date
    idx_rec_missing = isnat(data.Fecha_Recuperacion) & isnat(data.Fecha_Muerte);
    
    % Use recovery time distribution (lognormal)
    if any(idx_rec_missing)
        % Mean 14 days, standard deviation 7 days
        recovery_times = 14 + randn(sum(idx_rec_missing), 1) * 7;
        recovery_times(recovery_times < 7) = 7;
        recovery_times(recovery_times > 45) = 45;
        
        data.Fecha_Recuperacion(idx_rec_missing) = ...
            data.Fecha_Inicio_Sintomas(idx_rec_missing) + days(recovery_times);
        
        fprintf('- Imputed recoveries: %d cases\n', sum(idx_rec_missing));
    end
    
    % e) Validate death dates
    idx_death_inconsistent = ~isnat(data.Fecha_Muerte) & ...
                               (data.Fecha_Muerte < data.Fecha_Inicio_Sintomas);
    n_death_incons = sum(idx_death_inconsistent);
    
    if any(idx_death_inconsistent)
        fprintf('- Inconsistent deaths (before symptoms): %d cases\n', n_death_incons);
        % Impute: death = symptoms + mortality distribution
        mortality_times = avg_mortality_days + randn(n_death_incons, 1) * 5;
        mortality_times(mortality_times < 7) = 7;
        data.Fecha_Muerte(idx_death_inconsistent) = ...
            data.Fecha_Inicio_Sintomas(idx_death_inconsistent) + days(mortality_times);
    end
    
    % 3. CALCULATE ESTIMATED SEIR DATES
    fprintf('\n=== VARIABLE CALCULATION ===\n');
    
    % Infection date = symptom start - incubation
    data.infection_date = data.Fecha_Inicio_Sintomas - days(avg_incubation);
    
    % Infectiousness start date = symptom start - presymptomatic period
    data.infectious_start_date = data.Fecha_Inicio_Sintomas - days(presymptomatic_period);
    
    % Infectiousness end date = infectiousness start + infection duration
    data.infectious_end_date = data.infectious_start_date + days(infection_duration);
    
    % Ensure end date is not less than start date
    idx_end_less = data.infectious_end_date < data.infectious_start_date;
    if any(idx_end_less)
        data.infectious_end_date(idx_end_less) = data.infectious_start_date(idx_end_less) + days(infection_duration);
    end
    
    % 4. CREATE DATE RANGE
    start_date = min(data.Fecha_Notificacion);
    end_date = max(data.Fecha_Notificacion);
    dates = (start_date:days(1):end_date)';
    n_days = length(dates);
    
    fprintf('Analysis range: %s to %s (%d days)\n', ...
        datestr(start_date, 'dd-mmm-yyyy'), ...
        datestr(end_date, 'dd-mmm-yyyy'), n_days);
    
    % 5. INITIALIZE VECTORS
    exposed = zeros(n_days, 1);
    infected = zeros(n_days, 1);
    recovered = zeros(n_days, 1);
    deaths = zeros(n_days, 1);
    active_infected = zeros(n_days, 1);
    
    % 6. PROCESS EACH DAY (optimized version)
    for i = 1:n_days
        current_date = dates(i);
        date_num = floor(datenum(current_date));
        
        % a) New exposed
        mask_exp = ~isnat(data.infection_date);
        if any(mask_exp)
            exposed_dates = floor(datenum(data.infection_date(mask_exp)));
            exposed(i) = sum(exposed_dates == date_num);
        end
        
        % b) New infected
        mask_inf = ~isnat(data.infectious_start_date);
        if any(mask_inf)
            infected_dates = floor(datenum(data.infectious_start_date(mask_inf)));
            infected(i) = sum(infected_dates == date_num);
        end
        
        % c) Recovered (considering imputations)
        mask_rec = ~isnat(data.Fecha_Recuperacion);
        if any(mask_rec)
            recovered_dates = floor(datenum(data.Fecha_Recuperacion(mask_rec)));
            recovered(i) = sum(recovered_dates == date_num);
        end
        
        % d) Deaths
        mask_deaths = ~isnat(data.Fecha_Muerte);
        if any(mask_deaths)
            death_dates = floor(datenum(data.Fecha_Muerte(mask_deaths)));
            deaths(i) = sum(death_dates == date_num);
        end
        
        % e) Active infected
        mask_active = ~isnat(data.infectious_start_date) & ~isnat(data.infectious_end_date);
        if any(mask_active)
            start_dates = floor(datenum(data.infectious_start_date(mask_active)));
            end_dates = floor(datenum(data.infectious_end_date(mask_active)));
            active_infected(i) = sum((start_dates <= date_num) & (end_dates >= date_num));
        end
    end
    
    % 8. CREATE RESULTS TABLE
    Results_Dataset_Villavicencio = table(dates, exposed, infected, recovered, ...
                             deaths, active_infected, ...
                             'VariableNames', {'fecha', 'expuestos', 'infectados', ...
                                              'recuperados', 'muertos', ...
                                              'infectados_activos'});
    
    % 9. DISPLAY ENHANCED SUMMARY
    display_complete_summary(Results_Dataset_Villavicencio, total_population, data);
    
    % 10. GENERATE VALID PLOTS
    generate_valid_plots(Results_Dataset_Villavicencio);
    
    % 11. SAVE RESULTS AND IMPUTATION LOG
    save_complete_results(Results_Dataset_Villavicencio, data);
end

function display_complete_summary(data, total_population, original_data)
    fprintf('\n==========================================\n');
    fprintf('ADJUSTED EPIDEMIOLOGICAL SUMMARY - VILLAVICENCIO\n');
    fprintf('==========================================\n');
    
    % Data quality statistics
    n_total_cases = height(original_data);
    n_with_recovery = sum(~isnat(original_data.Fecha_Recuperacion));
    n_with_death = sum(~isnat(original_data.Fecha_Muerte));
    
    fprintf('ORIGINAL DATA QUALITY:\n');
    fprintf('- Total cases: %d\n', n_total_cases);
    fprintf('- With recovery date: %d (%.1f%%)\n', n_with_recovery, n_with_recovery/n_total_cases*100);
    fprintf('- With death date: %d (%.1f%%)\n', n_with_death, n_with_death/n_total_cases*100);
    fprintf('\n');
    
    % Adjusted model statistics
    total_infected = sum(data.infectados);
    total_recovered = sum(data.recuperados);
    total_deaths = sum(data.muertos);
    total_exposed = sum(data.expuestos);
    
    fprintf('ADJUSTED MODEL RESULTS:\n');
    fprintf('- Total exposed (E): %d\n', total_exposed);
    fprintf('- Total infected (I): %d\n', total_infected);
    fprintf('- Total recovered (R): %d\n', total_recovered);
    fprintf('- Total deaths (D): %d\n', total_deaths);
    fprintf('\n');
    
    % Model validation
    detected_cases = total_infected + total_recovered + total_deaths;
    fprintf('VALIDATION:\n');
    fprintf('- Cases detected in data: %d\n', n_total_cases);
    fprintf('- Cases in model: %d\n', detected_cases);
    fprintf('- Difference: %d (%.1f%%)\n', abs(n_total_cases-detected_cases), ...
            abs(n_total_cases-detected_cases)/n_total_cases*100);
    fprintf('\n');
    
    % Epidemiological rates
    if total_infected > 0
        fatality_rate = (total_deaths / total_infected) * 100;
        recovery_rate = (total_recovered / total_infected) * 100;
        fprintf('EPIDEMIOLOGICAL RATES:\n');
        fprintf('- Fatality rate: %.2f%%\n', fatality_rate);
        fprintf('- Recovery rate: %.2f%%\n', recovery_rate);
        fprintf('- R/D ratio: %.2f\n', total_recovered/max(total_deaths, 1));
    end
    
    % Peaks
    [peak_inf, idx_peak_inf] = max(data.infectados);
    [peak_rec, idx_peak_rec] = max(data.recuperados);
    [peak_act, idx_peak_act] = max(data.infectados_activos);
    
    fprintf('\nEPIDEMIC PEAKS:\n');
    fprintf('- New infected: %d on %s\n', peak_inf, datestr(data.fecha(idx_peak_inf), 'dd-mmm-yyyy'));
    fprintf('- New recovered: %d on %s\n', peak_rec, datestr(data.fecha(idx_peak_rec), 'dd-mmm-yyyy'));
    fprintf('- Active infected: %d on %s\n', peak_act, datestr(data.fecha(idx_peak_act), 'dd-mmm-yyyy'));
    
    % Final state
    R_final = sum(data.recuperados);
    D_final = sum(data.muertos);
    
    fprintf('\nFINAL STATE:\n');
    fprintf('- Recovered: %d (%.1f%%)\n', R_final, R_final/total_population*100);
    fprintf('- Deaths: %d (%.1f%%)\n', D_final, D_final/total_population*100);
    fprintf('- Total affected: %d (%.1f%%)\n', R_final + D_final, (R_final + D_final)/total_population*100);
    
    fprintf('==========================================\n');
end

function generate_valid_plots(data)
    % Figure 1: Infected and Recovered
    figure('Name', 'EPIDEMIC DYNAMICS - VILLAVICENCIO (With Imputation)', ...
           'Position', [100 100 1400 600]);
    
    % Subplot 1: Infected
    subplot(1,2,1);
    plot(data.fecha, data.infectados, 'r-', 'LineWidth', 2);
    hold on;
    
    % Smooth with moving average (7 days)
    infected_smoothed = movmean(data.infectados, 7);
    plot(data.fecha, infected_smoothed, 'r--', 'LineWidth', 1.5);
    
    % Mark peak
    [peak_inf, idx_peak_inf] = max(data.infectados);
    plot(data.fecha(idx_peak_inf), peak_inf, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    
    title('New Infected per Day', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Date', 'FontSize', 12);
    ylabel('Number of Cases', 'FontSize', 12);
    grid on;
    legend('Daily data', 'Moving average (7 days)', sprintf('Peak: %d', peak_inf), ...
           'Location', 'best');
    xlim([data.fecha(1) data.fecha(end)]);
    
    % Subplot 2: Recovered
    subplot(1,2,2);
    plot(data.fecha, data.recuperados, 'b-', 'LineWidth', 2);
    hold on;
    
    % Smooth with moving average
    recovered_smoothed = movmean(data.recuperados, 7);
    plot(data.fecha, recovered_smoothed, 'b--', 'LineWidth', 1.5);
    
    % Mark peak
    [peak_rec, idx_peak_rec] = max(data.recuperados);
    plot(data.fecha(idx_peak_rec), peak_rec, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    
    title('New Recovered per Day', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Date', 'FontSize', 12);
    ylabel('Number of Cases', 'FontSize', 12);
    grid on;
    legend('Daily data', 'Moving average (7 days)', sprintf('Peak: %d', peak_rec), ...
           'Location', 'best');
    xlim([data.fecha(1) data.fecha(end)]);
    
    % Figure 2: Cumulative comparison
    figure('Name', 'CUMULATIVE COMPARISON - VILLAVICENCIO', 'Position', [100 100 1200 500]);
    
    % Cumulative infected vs cumulative recovered
    infected_cum = cumsum(data.infectados);
    recovered_cum = cumsum(data.recuperados);
    deaths_cum = cumsum(data.muertos);
    
    plot(data.fecha, infected_cum, 'r-', 'LineWidth', 2);
    hold on;
    plot(data.fecha, recovered_cum, 'b-', 'LineWidth', 2);
    plot(data.fecha, deaths_cum, 'k-', 'LineWidth', 2);
    
    title('Cumulative Cases: Infected vs Recovered vs Deaths', ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Date', 'FontSize', 12);
    ylabel('Cumulative Cases', 'FontSize', 12);
    grid on;
    legend(sprintf('Infected: %d', infected_cum(end)), ...
           sprintf('Recovered: %d', recovered_cum(end)), ...
           sprintf('Deaths: %d', deaths_cum(end)), ...
           'Location', 'best');
    xlim([data.fecha(1) data.fecha(end)]);
end

function save_complete_results(SEIR_data, original_data)
    % Save main results
    Results_Dataset_Villavicencio=SEIR_data;
    save('Results_Dataset_Villavicencio.mat', 'Results_Dataset_Villavicencio');
    fprintf('\nResults saved in: Results_Dataset_Villavicencio.mat\n');
    
    % Save imputation statistics
    stats = struct();
    stats.n_original_cases = height(original_data);
    stats.n_imputed_recoveries = sum(isnat(original_data.Fecha_Recuperacion));
    stats.n_imputed_symptom_dates = sum(isnat(original_data.Fecha_Inicio_Sintomas));
    stats.start_date = min(SEIR_data.fecha);
    stats.end_date = max(SEIR_data.fecha);
    stats.total_population = 553409;
    
    % Calculate final statistics
    stats.total_infected = sum(SEIR_data.infectados);
    stats.total_recovered = sum(SEIR_data.recuperados);
    stats.total_deaths = sum(SEIR_data.muertos);
    
    % Save statistics to file
    save('imputation_statistics_villavicencio.mat', 'stats');
    
    % Create text report
    fid = fopen('imputation_report_villavicencio.txt', 'w');
    fprintf(fid, 'DATA IMPUTATION REPORT - VILLAVICENCIO\n');
    fprintf(fid, '========================================\n\n');
    fprintf(fid, 'Generation date: %s\n\n', datestr(now));
    
    fprintf(fid, 'IMPUTATION STATISTICS:\n');
    fprintf(fid, '- Original cases: %d\n', stats.n_original_cases);
    fprintf(fid, '- Imputed recoveries: %d\n', stats.n_imputed_recoveries);
    fprintf(fid, '- Imputed symptom dates: %d\n', stats.n_imputed_symptom_dates);
    fprintf(fid, '\n');
    
    fprintf(fid, 'FINAL RESULTS:\n');
    fprintf(fid, '- Total infected: %d\n', stats.total_infected);
    fprintf(fid, '- Total recovered: %d\n', stats.total_recovered);
    fprintf(fid, '- Total deaths: %d\n', stats.total_deaths);
    
    fclose(fid);
    fprintf('Imputation report saved in: imputation_report_villavicencio.txt\n');
end
