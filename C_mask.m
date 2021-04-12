function C_mask
%make healed T1 where T1+T2+Lesion exist
pth = '/home/chris/natalie/out'; %output path
tmp = '/home/chris/natalie/tmp';
outpth = '/home/chris/natalie/bout';

T1s = dirNii(fullfile(pth, 'eT1*'));
for s = 1 : numel(T1s)
    if exist(tmp, 'dir'), rmdir(tmp, 's'); end;
    mkdir(tmp)
    T1 = T1s{s};
    [p,n] = fileparts(T1);
    subj = strsplit(n,{'.','_'});
    subj = subj{2};
    T2 = dirNii1(fullfile(p, ['T2_',subj,'*']));
    if isempty(T2), continue; end
    FL = dirNii1(fullfile(p, ['erFLAIR_',subj,'*']));
    if isempty(FL), continue; end
    les = dirNii1(fullfile(p, ['LESION_',subj,'*']));
    if isempty(les), continue; end
    T1 = nii_copy(T1, tmp, '');
    T2 = nii_copy(T2, tmp, '');
    les = nii_copy(les, tmp, '');
    FL = nii_copy(FL, tmp, '');
    [eT1, rlesion, eT2, eFLAIR ] = enat(T1,les,T2, FL);
    %eT1 = '/home/chris/natalie/tmp/eT1_M2001.nii'
    mat = flirtSub(eT1);
    fprintf('%s %s %s %s\n', eT1, rlesion, eT2, eFLAIR );
    nii_copy(eT1, outpth, '');
    nii_copy(eT2, outpth, '');
    nii_copy(rlesion, outpth, '');
    nii_copy(eFLAIR, outpth, '');
end
%end B_enat()

function fsldir = fslDirSub()
fsldir= '/usr/local/fsl/';
if ~exist(fsldir, 'dir')
   error('Unable to find %s\n', fsldir); 
end
%end fslDirSub()

function mat = flirtSub(fnm)
[p,n] = fileparts(fnm);
mat = fullfile(p,[n,'.mat']);
fsldir = fslDirSub();
fslCmdSub(sprintf('flirt -in %s -ref %s/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12', fnm, fsldir, mat));
%end flirtSub()

function fslCmdSub (Cmd)
%execute a fsl command, e.g. fslCmd('fslinfo a.nii');
fsldir = fslDirSub();
if ~exist(fsldir,'dir')
	error('%s: fsldir (%s) not found',mfilename, fsldir);
end
setenv('FSLDIR', fsldir);
flirt = [fsldir 'bin/flirt'];
if ~exist(flirt,'file')
	error('%s: flirt (%s) not found',mfilename,flirt);
end
command=sprintf('sh -c ". %setc/fslconf/fsl.sh; %sbin/%s"\n',fsldir,fsldir, Cmd);
fprintf(command);
system(command);
%end fslCmdSub()

function outnii = nii_copy(fnm, outdir, outnm, copyJsonBvec)
if ~exist(outdir, 'dir'), return; end
if ~exist('copyJsonBvec', 'var'), copyJsonBvec = true; end;
[p,n,x] = fileparts(fnm);
if endsWith(fnm, '.nii.gz')
   [~, n] = fileparts(n);
   x = '.nii.gz';
end
if isempty(outnm), outnm = n; end;
outnii = fullfile(outdir, [outnm, x]);
%fprintf('%s->%s\n', fnm, outnii);
if exist(outnii,'file')
    error('Overwrites should never happen %s\n', outnii);
end
copyfile(fnm, outnii);
if endsWith(outnii, '.nii.gz')
   d = gunzip(outnii);
   delete(outnii);
   outnii = d{1};
end
if (~copyJsonBvec), return; end
copyfilex(fullfile(p, [n, '.mat']), fullfile(outdir, [outnm, '.mat']));
copyfilex(fullfile(p, [n, '.json']), fullfile(outdir, [outnm, '.json']));
copyfilex(fullfile(p, [n, '.bvec']), fullfile(outdir, [outnm, '.bvec']));
copyfilex(fullfile(p, [n, '.bval']), fullfile(outdir, [outnm, '.bval']));
%end nii_copy()

function dst = copyfilex(src, dst)
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