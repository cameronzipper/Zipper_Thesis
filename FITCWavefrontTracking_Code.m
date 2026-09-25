%% FITC front velocity - cross-channel profile V(x)
% rows = streamwise (y), columns = cross-channel (x)

clear; close all;

pxSize  = 2000/588;   % [um/px]
dtFrame = 1;          % [s/frame]
step    = 5;          % use every nth frame
nRef    = 3;          % frames averaged for bg / peak
nBins   = 32;         % cross-channel bins
thr     = 0.5;        % arrival threshold (normalised c)
endFrac = 0.15;       % fraction of rows at each end for the endpoints (< 0.5)
minRows = 10;         % min valid rows per bin

parent = uigetdir(pwd, 'Select parent folder');
d = dir(parent);
subs = {d([d.isdir] & ~ismember({d.name},{'.','..'})).name};
nSet = numel(subs);

% draw all ROIs up front
rois = cell(1,nSet);
for i = 1:nSet
    rois{i} = draw_roi(fullfile(parent,subs{i}), ...
        sprintf('[%d/%d] %s - draw ROI, double-click to confirm', i, nSet, subs{i}));
end

R = cell(1,nSet);
for i = 1:nSet
    folder = fullfile(parent, subs{i});
    names = list_tifs(folder);
    idx = 1:step:numel(names);
    names = names(idx);
    nF = numel(names);
    t = (idx(:) - 1) * dtFrame;

    roi = rois{i};
    nRows = roi(2) - roi(1) + 1;
    nCols = roi(4) - roi(3) + 1;
    edges = round(linspace(0, nCols, nBins+1));

    % bin-averaged intensity I(row, bin, t)
    P = zeros(nRows, nBins, nF, 'single');
    for k = 1:nF
        g = single(mean(imread(fullfile(folder,names{k}), 'PixelRegion', {roi(1:2), roi(3:4)}), 3));
        for b = 1:nBins
            P(:,b,k) = mean(g(:, edges(b)+1:edges(b+1)), 2);
        end
    end

    % normalise to first (dark) and last (loaded) frames
    bg  = mean(P(:,:,1:nRef), 3);
    pk  = mean(P(:,:,end-nRef+1:end), 3);
    den = pk - bg;
    den(den <= 0) = NaN;
    C = (P - bg) ./ den;

    % arrival time per (row, bin)
    T = nan(nRows, nBins);
    for b = 1:nBins
        for r = 1:nRows
            c = squeeze(C(r,b,:));
            k = find(c >= thr, 1);
            if isempty(k) || k < 2, continue; end
            T(r,b) = t(k-1) + (thr - c(k-1))/(c(k) - c(k-1)) * (t(k) - t(k-1));
        end
    end

    % velocity per bin from median arrival at each end
    y = (1:nRows)' * pxSize;
    v = nan(nBins,1); yLo = v; yHi = v;
    for b = 1:nBins
        ok = isfinite(T(:,b));
        if nnz(ok) < minRows, continue; end
        yy = y(ok); TT = T(ok,b);
        m  = max(1, round(endFrac*numel(yy)));
        yl = median(yy(1:m));
        yh = median(yy(end-m+1:end));
        dT = median(TT(end-m+1:end)) - median(TT(1:m));
        if dT <= 0 || yh <= yl, continue; end
        v(b) = (yh - yl) / dT;
        yLo(b) = yl; yHi(b) = yh;
    end

    x  = ((edges(1:end-1) + edges(2:end)) / 2)' * pxSize;
    xe = edges * pxSize;

    % arrival time map, red = anchor rows
    f = figure('Visible','off');
    him = imagesc(x, y, T);
    set(him, 'AlphaData', isfinite(T));
    colormap(parula); cb = colorbar; cb.Label.String = 'Arrival time (s)';
    hold on;
    for b = find(isfinite(v))'
        plot(xe(b:b+1), [yLo(b) yLo(b)], 'r-', 'LineWidth', 2);
        plot(xe(b:b+1), [yHi(b) yHi(b)], 'r-', 'LineWidth', 2);
    end
    xlabel('Cross-channel position (\mum)');
    ylabel('Streamwise position (\mum)');
    title(subs{i}, 'Interpreter', 'none');
    saveas(f, fullfile(parent, sprintf('Tmap_%s.png', matlab.lang.makeValidName(subs{i}))));
    close(f);

    R{i} = struct('x', x, 'v', v);
end

%% V(x)
figure; hold on; grid on;
for i = 1:nSet
    plot(R{i}.x, R{i}.v, 'o-', 'LineWidth', 1.5, 'DisplayName', subs{i});
end
xlabel('Cross-channel position (\mum)');
ylabel('Front speed (\mum/s)');
title('Cross-channel velocity profile');
legend('Location', 'best', 'Interpreter', 'none');

%% CSV on a common x grid (ROI widths differ slightly between datasets)
xg = linspace(max(cellfun(@(r) min(r.x), R)), min(cellfun(@(r) max(r.x), R)), nBins)';
V = nan(nBins, nSet);
for i = 1:nSet
    ok = isfinite(R{i}.v);
    if nnz(ok) > 1
        V(:,i) = interp1(R{i}.x(ok), R{i}.v(ok), xg, 'linear', NaN);
    end
end
writetable(array2table([xg V], 'VariableNames', [{'X_um'}, matlab.lang.makeValidName(subs)]), ...
    fullfile(parent, 'velocity_profiles.csv'));
fprintf('Done\n');


%% functions
function roi = draw_roi(folder, ttl)
    names = list_tifs(folder);
    img = mean(imread(fullfile(folder, names{end})), 3);   % last frame
    fh = figure('Name', 'Draw ROI', 'NumberTitle', 'off', 'Position', [100 100 900 600]);
    imagesc(img); axis image; colormap(gray);
    title(ttl, 'Interpreter', 'none');
    h = drawrectangle(gca, 'Color', 'y');
    wait(h);
    p = round(h.Position);
    close(fh);
    roi = [p(2), p(2)+p(4)-1, p(1), p(1)+p(3)-1];
end

function names = list_tifs(folder)
    d = [dir(fullfile(folder,'*.tif')); dir(fullfile(folder,'*.tiff'))];
    names = {d.name};
    n = nan(numel(names),1);
    for i = 1:numel(names)
        tok = regexp(names{i}, '\d+', 'match');
        if ~isempty(tok), n(i) = str2double(tok{end}); end
    end
    if all(~isnan(n)), [~,o] = sort(n); else, [~,o] = sort(names); end
    names = names(o);
end