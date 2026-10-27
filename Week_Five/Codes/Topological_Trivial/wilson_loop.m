%% =====================================================================
% Wilson Loop Topological Analysis: Phase Unwrapping & Range [0, 0.5]
%% =====================================================================
function analyze_wilson_topology_unwrapped()
    % Analyze both systems with forced phase unwrapping
    process_unwrapped('Wilsonloop_Rashba_System.dat', 'Rashba System');
    process_unwrapped('Wilsonloop_Dresselhaus_System.dat', 'Dresselhaus System');
end

function process_unwrapped(filename, system_name)
    if exist(filename, 'file') ~= 2
        fprintf('Error: File %s not found.\n', filename);
        return;
    end
    
    data = readmatrix(filename);
    kx = data(:, 1);
    raw_wcc = data(:, 2:3);
    
    % --- Step 1: Unwrapping ---
    % Force the phase to be continuous. 
    % We multiply by 2*pi because unwrap() works on radians.
    unwrapped_wcc = unwrap(raw_wcc * 2 * pi) / (2 * pi);
    
    % --- Step 2: Restrict to [0, 0.5] ---
    mask = (kx >= 0) & (kx <= 0.5);
    kx_sub = kx(mask);
    wcc_sub = unwrapped_wcc(mask, :);
    
    % --- Step 3: Visualization ---
    figure('Name', ['Unwrapped Loop [0, 0.5]: ', system_name], 'Color', 'w', 'Position', [100, 100, 600, 450]);
    hold on; grid on; box on;
    
    % Plot the stretched bands
    plot(kx_sub, wcc_sub(:, 1), '-b', 'LineWidth', 2);
    plot(kx_sub, wcc_sub(:, 2), '-r', 'LineWidth', 2);
    
    % Plot the reference line at 0.25
    yline(0.25, '--g', 'LineWidth', 2);
    
    % --- Step 4: Robust Intersection Counting ---
    % Count crossings only where bands clearly pass 0.25
    crossings = 0;
    for b = 1:2
        % Identify crossings relative to 0.25
        signal = wcc_sub(:, b) - 0.25;
        crossings = crossings + sum(abs(diff(sign(signal))) > 0);
    end
    
    % Annotate
    text(0.02, 0.45, ['Crossings in [0, 0.5]: ', num2str(crossings)], ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
    
    xlabel('k_x / 2\pi'); 
    ylabel('\theta (Unwrapped)');
    title([system_name, ' (Forced Unwrapping)']);
    xlim([0, 0.5]); 
    % Dynamically set y-limits to see the 0.5 reach
    ylim([-0.1, 0.6]); 
    legend('Band 1', 'Band 2', 'Location', 'best');
    set(gca, 'FontSize', 12);
end