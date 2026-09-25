% Mean velocity vs X, averaged over Y/Z within a Y band (NaN ignored)
clear;

file = 'C:\Users\julie\Downloads\2dtop.csv';
M = readmatrix(file, 'NumHeaderLines', 9);
raw = readcell(file);
labels = raw(9, 4:end);   % pressure head names

x = M(:,1); y = M(:,2); V = M(:,4:end);

% Y band to keep
y_min = 1.25e-3;
y_max = 1.75e-3;
keep = (y >= y_min) & (y <= y_max);
x = x(keep);
V = V(keep,:);

xu = unique(x);
mv = nan(numel(xu), size(V,2));
for i = 1:numel(xu)
    rows = (x == xu(i));
    for h = 1:size(V,2)
        mv(i,h) = mean(V(rows,h), 'omitnan');
    end
end

writecell([[{'x'}, labels]; num2cell([xu mv])], '2dtop.xlsx');