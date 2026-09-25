%% PIVlab ensemble post-processing
% Run straight after PIVlab export to workspace (don't clear)

clc;

dev     = 4;
H_cm    = 0.5;
chamber = 'Center';
flowDir = 'down';        % 'up' or 'down' based on video

umPerPx = 1000/304;
nFrames = 451;
tVideo  = 60;            % [s]
dt      = tVideo / nFrames;

xlsFile = 'Zipper_DiffusionLimited_BeadData1.xlsx';

% PIVlab field (filtered if available)
if exist('u_filtered','var') && ~isempty(u_filtered) && numel(u_filtered{1}) > 1
    u = u_filtered{1}; v = v_filtered{1}; tv = typevector_filtered{1};
else
    u = u_original{1}; v = v_original{1}; tv = typevector_original{1};
end

Vx = double(u) * umPerPx / dt;   % [um/s]
Vy = double(v) * umPerPx / dt;
if strcmpi(flowDir, 'up'), Vy = -Vy; end
Vx(tv == 0) = NaN;
Vy(tv == 0) = NaN;

% average over y for each x column
n  = sum(~isnan(Vy), 1)';
vx = abs(mean(Vx, 1, 'omitnan'))';
vy = mean(Vy, 1, 'omitnan')';
sx = std(Vx, 0, 1, 'omitnan')';
sy = std(Vy, 0, 1, 'omitnan')';
sx(n < 2) = NaN;
sy(n < 2) = NaN;
ex = sx ./ sqrt(n);
ey = sy ./ sqrt(n);

vm = sqrt(vx.^2 + vy.^2);
sm = sqrt(sx.^2 + sy.^2);
em = sqrt(ex.^2 + ey.^2);

X = double(x{1}(1,:))' * umPerPx;

T = table(X, vx, vy, vm, sx, sy, sm, ex, ey, em, n, ...
    'VariableNames', {'X_um', 'Vx_um_s', 'Vy_um_s', 'V_um_s', ...
    'Vx_Std_um_s', 'Vy_Std_um_s', 'V_Std_um_s', ...
    'Vx_SE_um_s', 'Vy_SE_um_s', 'V_SE_um_s', 'nVectors'});
T = T(~isnan(vm), :);
T.X_um = T.X_um - mean([min(T.X_um) max(T.X_um)]);   % centre on channel

% new sheet per run, numbered if the name is taken
sheet = sprintf('Dev%d_%.4gcm_%s', dev, H_cm, chamber);
if isfile(xlsFile)
    existing = sheetnames(xlsFile);
    base = sheet; k = 1;
    while ismember(sheet, existing)
        k = k + 1;
        sheet = sprintf('%s_%d', base, k);
    end
end
writetable(T, xlsFile, 'Sheet', sheet);
fprintf('Done\n');