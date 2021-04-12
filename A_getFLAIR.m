function A_getFLAIR
%pull scans for each person where FLAIR+T1+T2+Lesion exist
pth = '/media/chris/Chris5TB/Universe/master'; %folder with images
outdir = '/home/chris/natalie/FLAIRS'; %output path

spths = dirDir(fullfile(pth, 'M*'));
for s = 1 : numel(spths)
    spth = spths{s};
    [~, snam] = fileparts(spth);
    lpth = dirDir(fullfile(spth, 'Lesion_Mapp*'));
    if isempty(lpth), 
        %warning('Unable to find Lesion Mapping for %s', spth);
        continue;
    end
    lpth = lpth{1};
    T1 = dirNii1(fullfile(lpth, 'T1*'));
    if isempty(T1),  continue; end
    T2 = dirNii1(fullfile(lpth, 'T2*'));
    if isempty(T2),  continue; end
    les = dirNii1(fullfile(lpth, 'LESION*'));
    if isempty(les),  continue; end
    %check each visit for FLAIR
    vpths = dirDir(fullfile(spth, '*'));
    FLs = {};
    for v = 1 : numel(vpths)
        vpth = vpths{v};
        FL = dirNii1(fullfile(vpth, 'FLAIR*'), false);
        if isempty(FL),  continue; end 
        FLs = [FLs, FL];
    end
    if isempty(FLs), continue; end
    nii_copy(T1, outdir, ['T1_', snam]);
    nii_copy(T2, outdir, ['T2_', snam]);
    nii_copy(les, outdir, ['LESION_', snam]);
    for f = 1 : numel(FLs)
        onm = ['FLAIR_', snam, '_', num2str(f), '_', scandate(FLs{f})];
        %fprintf('%s\n', onm);
        nii_copy(FLs{f}, outdir, onm, false);
    end  
end
%end getFLAIR

function dt = scandate(fnm)
% e.g. 20170105 for ~/master/M4217/CT_20170105_090959_6M_CT217/FLAIR.nii'
dt = '';
p = fileparts(fnm); %path
[~, n] = fileparts(p); %final folder
parts = strsplit(n,'_');
if numel(parts) < 2, return; end
dt = parts{2};
if (numel(dt) > 8), dt = dt(1:8); end
%

function nii_copy(fnm, outdir, outnm, copyJsonBvec)
if ~exist(outdir, 'dir'), return; end
if ~exist('copyJsonBvec', 'var'), copyJsonBvec = true; end;
[p,n,x] = fileparts(fnm);
if endsWith(fnm, '.nii.gz')
   [~, n] = fileparts(n);
   x = '.nii.gz';
end
outnii = fullfile(outdir, [outnm, x]);
fprintf('%s-%s\n', fnm, outnii);
if exist(outnii,'file')
    error('Overwrites should never happen %s\n', outnii);
end
copyfile(fnm, outnii);
if (~copyJsonBvec), return; end
copyfilex(fullfile(p, [n, '.json']), fullfile(outdir, [outnm, '.json']));
copyfilex(fullfile(p, [n, '.bvec']), fullfile(outdir, [outnm, '.bvec']));
copyfilex(fullfile(p, [n, '.bval']), fullfile(outdir, [outnm, '.bval']));
%end nii_copy()

function copyfilex(src, dst)
if ~exist(src, 'file'), return; end
copyfile(src,dst);
%copyfilex()

function fnm = dirNii1(pth, warn)
%return 1st Nifti
if ~exist('warn', 'var'), warn = true; end 
fnm = dirNii(pth);
if isempty(fnm) 
    if (warn), warning('Unable to find NIfTI for %s', pth); end
    return;
end
fnm = fnm{1};
%end dirNii1

function fnms = dirX(pth, isDir, isNIfTI)
%sorted list of filenames, hidden and empty files removed
%return folders {'/home/chris/M1', '/home/chris/M3'}
% fnms = dirX(/home/chris/M*, true)
%return NIfTIs {'/home/chris/M1.nii', '/home/chris/M3.nii.gz'}
% fnms = dirX(/home/chris/M*, false, true)
%return JSONs
% fnms = dirX(/home/chris/*.json, false, true)

d = dir(pth);
d = d(~startsWith({d.name}, '.'));
if isDir
    isub = [d(:).isdir];
else
    
    isub = ~[d(:).isdir] & ([d(:).bytes] > 0);
    if exist('isNIfTI','var') && isNIfTI
       nii = endsWith({d.name}, '.nii') | endsWith({d.name}, '.nii.gz');
       isub = isub & nii;
    end
end
fnms = {d(isub).name}';
[~,idx] = sort(upper(fnms));
fnms = fnms(idx);
fnms = strcat(fileparts(pth), filesep, fnms);

function fnms = dirDir(pth)
%sorted list of filenames, hidden and empty files removed
%return folders {'/home/chris/M1', '/home/chris/M3'}
fnms = dirX(pth, true);

function fnms = dirNii(pth)
%sorted list of filenames, hidden and empty files removed
%return folders {'/home/chris/M1', '/home/chris/M3'}
fnms = dirX(pth, false, true);

