% WMV -> TIF frames
% Container fps isn't reliable for the time-lapse exports (frames get
% duplicated), so sample by timestamp at the real acquisition interval.

clear; clc;

dt = 1;  % acquisition interval (s)

[files, folder] = uigetfile('*.wmv', 'Select WMV files', 'MultiSelect', 'on');
if isequal(files, 0), return; end
if ischar(files), files = {files}; end

for f = 1:numel(files)
    [~, name] = fileparts(files{f});
    outDir = fullfile(folder, [name '_tiffs']);
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    vr = VideoReader(fullfile(folder, files{f}));
    n = floor(vr.Duration / dt);

    for k = 1:n
        vr.CurrentTime = (k-1)*dt;
        if ~hasFrame(vr), break; end
        img = readFrame(vr);
        imwrite(img, fullfile(outDir, sprintf('frame_%05d.tif', k)), 'Compression', 'lzw');
    end

    fprintf('%s done\n', name);
end