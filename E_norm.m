function E_norm
%make healed T1 where T1+T2+Lesion exist
pth = '/home/chris/natalie/FLAIRS'; %path with T1
epth = '/home/chris/natalie/out'; %path with eT1
spth = '/home/chris/natalie/seg'; %path with BIANCA FLIARS

tmp = '/home/chris/natalie/tmp';
outpth = '/home/chris/natalie/warp';

T1s = dirNii(fullfile(pth, 'T1*'));
for s = 1 : numel(T1s)
    if exist(tmp, 'dir'), rmdir(tmp, 's'); end;
    mkdir(tmp)
    T1 = T1s{s};
    [p,n] = fileparts(T1);
    subj = strsplit(n,{'.','_'});
    subj = subj{2};
    segs = dirNii(fullfile(spth, [subj,'_*']));
    les = dirNii1(fullfile(epth, ['srLESION_',subj,'*']));
    if isempty(les), continue; end
    if isempty(segs), continue; end
    eT1 = dirNii1(fullfile(epth, ['eT1_',subj,'*']));
    if isempty(eT1), continue; end
    T1 = nii_copy(T1, tmp, '');
	eT1 = nii_copy(eT1, tmp, '');
	segs = nii_copies(segs, tmp, '');
    xT1 = unbet(eT1, T1);
    wsegs = normSub(xT1, [segs, eT1, les]);
    nii_copies(wsegs, outpth, '');
end
%end B_enat()

function writeimgs = normSub(T1, writeimgs, bb, vox);
if ~exist('bb','var'), bb = [-78 -112 -70; 78 76 85]; end;
if ~exist('vox','var'), vox =[1 1 1]; end;
template = fullfile(spm('Dir'),'tpm','TPM.nii');
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol = {T1};
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = writeimgs';%writeimgs;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {template};
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = bb;
matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = vox;
matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
spm_jobman('run',matlabbatch);
for i = 1 : numel(writeimgs)
  [p,n,x] = fileparts(writeimgs{i});
  writeimgs{i} = fullfile(p, ['w',n,x]);
end
%end normSub()

function xT1 = unbet(ebT1, T1)
% 'ebT1' is a brain extracted, healed T1
% 'T1' is the source scan with scalp and lesion
% creates 'xT1' where T1 gets all non-zero voxels from ebT1
% Therefore, 'xT1' has scalp but is healed.
[p,n,x] = fileparts(T1);
ehdr = spm_vol(ebT1);
eimg = spm_read_vols(ehdr);
hdr = spm_vol(T1);
img = spm_read_vols(hdr);
img(eimg ~=0) = eimg(eimg ~=0);
xT1 = fullfile(p, ['x',n,x]);
hdr.fname = xT1;  
spm_write_vol(hdr,img);
%

function fsldir = fslDirSub()
fsldir= '/usr/local/fsl/';
if ~exist(fsldir, 'dir')
   error('Unable to find %s\n', fsldir); 
end
%end fslDirSub()



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


function outniis = nii_copies(fnms, outdir, outnm, copyJsonBvec)
if ~exist(outdir, 'dir'), return; end
if ~exist('copyJsonBvec', 'var'), copyJsonBvec = true; end;
outniis = {};
for i = 1 : numel(fnms)
    fnm = fnms{i};
    outnii = nii_copy(fnm, outdir, outnm, copyJsonBvec);
    outniis = [outniis, {outnii}];
end
%end nii_copies()

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