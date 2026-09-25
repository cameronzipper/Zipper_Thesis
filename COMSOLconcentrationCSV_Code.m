%% wavefront_velocity.m
% Wavefront speed vs x from arrival time, one column per (HH, ECM_perm) pair

clear;

csv_in  = 'C:\Users\cameron\Downloads\DIFF2.csv';
csv_out = 'C:\Users\cameron\Downloads\Diff2_Processed.csv';

arrivalFrac = 0.16;   % c* as fraction of max c
minNodes    = 10;     % min valid y-nodes per x

%% header
fid = fopen(csv_in);
hdrLine = 0; ln = 0; header = '';
while true
    l = fgetl(fid); ln = ln + 1;
    if ~ischar(l), break; end
    ls = strtrim(l);
    if startsWith(ls, '% x,y,z') || (contains(ls,'ECM_perm') && contains(ls,'@ t='))
        header = l; hdrLine = ln; break;
    end
end
fclose(fid);

colnames = strsplit(regexprep(header, '^%\s*', ''), ',');
nc = numel(colnames);
tvec = nan(1,nc); hh = nan(1,nc); pm = nan(1,nc);

for k = 1:nc
    lab = colnames{k};
    tt = regexp(lab, 't=([\d.]+)', 'tokens', 'once');
    hk = regexp(lab, 'hh=([\d.]+)', 'tokens', 'once');
    pk = regexp(lab, 'ECM_perm=([\d.eE+\-]+)', 'tokens', 'once');
    if ~isempty(tt) && ~isempty(hk) && ~isempty(pk)
        tvec(k) = str2double(tt{1});
        hh(k)   = str2double(hk{1});
        pm(k)   = str2double(pk{1});
    end
end

valid = ~isnan(tvec) & ~isnan(hh) & ~isnan(pm);
pairs = unique([hh(valid)', pm(valid)'], 'rows');

%% data
data = readmatrix(csv_in, 'FileType','text', 'NumHeaderLines', hdrLine, 'Delimiter', ',');
[xu,~,ix] = unique(data(:,1));
[yu,~,iy] = unique(data(:,2));
nx = numel(xu); ny = numel(yu);
lin = sub2ind([ny nx], iy, ix);

out = table(xu*1e3, 'VariableNames', {'X_mm'});

for i = 1:size(pairs,1)
    cols = find(hh == pairs(i,1) & pm == pairs(i,2));
    [t, s] = sort(tvec(cols));
    cols = cols(s);
    nt = numel(t);

    % C(y,x,t)
    C = nan(ny, nx, nt);
    for k = 1:nt
        G = nan(ny,nx); G(lin) = data(:,cols(k)); C(:,:,k) = G;
    end

    % arrival time, interpolated between the two frames straddling c*
    cstar = arrivalFrac * max(C(:), [], 'omitnan');
    Tarr = nan(ny, nx);
    for jx = 1:nx
        for jy = 1:ny
            ct = squeeze(C(jy,jx,:));
            i1 = find(ct >= cstar, 1);
            if isempty(i1) || i1 == 1, continue; end
            c0 = ct(i1-1); c1 = ct(i1);
            if ~isfinite(c0) || c1 == c0, continue; end
            Tarr(jy,jx) = t(i1-1) + (cstar - c0)/(c1 - c0)*(t(i1) - t(i1-1));
        end
    end

    % velocity between top and bottom valid y-node [um/s]
    vel = nan(nx,1);
    for jx = 1:nx
        jj = find(isfinite(Tarr(:,jx)));
        if numel(jj) < minNodes, continue; end
        yv = yu(jj); Tv = Tarr(jj,jx);
        [~,ia] = max(yv); [~,ib] = min(yv);
        if Tv(ia) ~= Tv(ib)
            vel(jx) = abs((yv(ia)-yv(ib))/(Tv(ia)-Tv(ib))) * 1e6;
        end
    end

    name = matlab.lang.makeValidName(sprintf('V_HH%d_PM%.2e', pairs(i,1), pairs(i,2)));
    out.(name) = vel;
end

writetable(out, csv_out);
fprintf('Done\n');