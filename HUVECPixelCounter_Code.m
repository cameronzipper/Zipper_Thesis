%% HUVEC / spheroid pixel counts from paired FITC and TRITC images
clear; close all;

% parameters
sensStart = 0.45;   % starting HUVEC sensitivity on the slider
minSize   = 30;     % smallest HUVEC object kept (px)
maxSize   = 3000;   % largest HUVEC object kept (px)
padPx     = 15;     % spheroid exclusion zone padding (px)

% pick the images (FITC first, then TRITC)
[greenFiles, gPath] = uigetfile({'*.tif;*.tiff;*.png;*.jpg'}, ...
    'Select FITC (spheroid) images', 'MultiSelect', 'on');
[redFiles, rPath] = uigetfile({'*.tif;*.tiff;*.png;*.jpg'}, ...
    'Select TRITC (HUVEC) images', 'MultiSelect', 'on');
if ischar(greenFiles), greenFiles = {greenFiles}; end
if ischar(redFiles),   redFiles   = {redFiles};   end
greenFiles = sort(greenFiles);
redFiles   = sort(redFiles);
assert(numel(greenFiles) == numel(redFiles), 'Need matching numbers of images.');

results = table();

for k = 1:numel(greenFiles)
    gName = greenFiles{k};
    green = imread(fullfile(gPath, gName));
    red   = imread(fullfile(rPath, redFiles{k}));

    % spheroid mask
    g = norm01(green);
    spheroid = bwareafilt(imfill(imbinarize(g, graythresh(g)), 'holes'), 1);
    zone = imdilate(bwconvhull(spheroid), strel('disk', padPx));

    % HUVEC mask, threshold set by hand
    [huvec, sens] = pickHUVEC(red, zone, sensStart, minSize, maxSize);

    numGreen = nnz(spheroid);
    numRed   = nnz(huvec);

    dev = grabNum(gName, 'device');
    day = grabNum(gName, 'day');

    results = [results; table(dev, day, sens, numGreen, numRed, ...
        'VariableNames', {'Device','Day','Sensitivity','NumGreenPixels','NumRedPixels'})];
end

results = sortrows(results, {'Device','Day'});
writetable(results, fullfile(gPath, 'master_results.xlsx'));


%% functions
function out = norm01(img)
    if ndims(img) == 3, img = rgb2gray(img); end
    img = im2double(img);
    out = (img - min(img(:))) / (max(img(:)) - min(img(:)));
end

function [mask, sens] = pickHUVEC(red, zone, sens, minSize, maxSize)
    g = norm01(red);
    mask = redMask(sens);

    f = figure('Name', 'Set HUVEC sensitivity', 'NumberTitle', 'off');
    him = imshow(overlay(mask));
    ttl = title(sprintf('sensitivity %.2f    pixels %d', sens, nnz(mask)));
    sld = uicontrol('Style','slider','Units','normalized', ...
        'Position',[0.20 0.02 0.50 0.04], 'Min',0.01,'Max',0.99,'Value',sens, ...
        'Callback', @update);
    addlistener(sld, 'ContinuousValueChange', @update);
    uicontrol('Style','pushbutton','Units','normalized', ...
        'Position',[0.72 0.02 0.12 0.05], 'String','OK', 'Callback', @(~,~) uiresume(f));
    uiwait(f);
    if isvalid(f), close(f); end

    function m = redMask(sv)
        m = imbinarize(g, adaptthresh(g, sv, 'ForegroundPolarity','bright'));
        m = imfill(m, 'holes');
        cc = bwconncomp(m);
        a  = cellfun(@numel, cc.PixelIdxList);
        m  = ismember(labelmatrix(cc), find(a >= minSize & a <= maxSize));
        m(zone) = false;
    end
    function rgb = overlay(m)
        base = g; base(zone) = 0;
        rgb = labeloverlay(base, m, 'Colormap',[0 1 1], 'Transparency',0.5);
    end
    function update(src, ~)
        sens = src.Value;
        mask = redMask(sens);
        him.CData  = overlay(mask);
        ttl.String = sprintf('sensitivity %.2f    pixels %d', sens, nnz(mask));
        drawnow limitrate;
    end
end

function n = grabNum(name, key)
    tok = regexpi(name, [key '[_\s]*(\d+)'], 'tokens', 'once');
    if isempty(tok), n = NaN; else, n = str2double(tok{1}); end
end