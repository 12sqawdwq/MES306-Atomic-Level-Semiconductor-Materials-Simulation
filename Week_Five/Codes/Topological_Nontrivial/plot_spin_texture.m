%% ====================== MAIN FUNCTION ======================
function plot_all_textures_only()
    % Main function to plot Spin Textures
    
    % Plot Spin Texture for both systems
    plot_single_spin_texture('Rashba_Spin_Texture.dat', 'Rashba System');
    plot_single_spin_texture('DRESSELHAUS_Spin_Texture.dat', 'Dresselhaus System');
end

%% =====================================================================
% Subfunction: Spin Texture
% =====================================================================
function plot_single_spin_texture(filename, system_name)
    if exist(filename, 'file') ~= 2, return; end
    fid = fopen(filename, 'r'); if fid == -1, return; end
    bands = cell(1, 4); band_idx = 1; current_band_data = [];
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if isempty(line)
            if ~isempty(current_band_data)
                bands{band_idx} = current_band_data; band_idx = band_idx + 1; current_band_data = [];
                if band_idx > 4, break; end
            end
            continue;
        end
        num_data = sscanf(line, '%f');
        if length(num_data) == 6, current_band_data = [current_band_data; num_data']; end
    end
    if ~isempty(current_band_data) && band_idx <= 4, bands{band_idx} = current_band_data; end
    fclose(fid);
    
    for b = 1:4
        data = bands{b}; if isempty(data), continue; end
        kx = data(:, 1); ky = data(:, 2); kz = data(:, 3); sx = data(:, 4); sy = data(:, 5); sz = data(:, 6);
        figure('Name', sprintf('%s - Band %d', system_name, b), 'Color', 'w');
        
        if all(kz == 0) && all(sz == 0)
            % 2D Spin Texture
            quiver(kx, ky, sx, sy, 0.5, 'LineWidth', 1.2); hold on;
            plot(kx, ky, 'o', 'MarkerSize', 3, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none'); view(2);
        else
            % 3D Spin Texture
            scatter3(kx, ky, kz, 30, sz, 'filled', 'MarkerEdgeColor', 'k'); hold on;
            quiver3(kx, ky, kz, sx, sy, sz, 0.6, 'LineWidth', 1.2); colormap(jet); view(3);
        end
        grid on; box on; axis equal;
        title(sprintf('%s - Band %d', system_name, b));
    end
end