function D_make_bianca_masterfile
%make healed T1 where T1+T2+Lesion exist
pth = '/home/chris/natalie/out'; %path with healed images

T1s = dirNii(fullfile(pth, 'eT1*'));
healnm = 'biancaHealed.txt';
%fid = fopen(healnm,'w');
fid2 = fopen('cmds.txt','w');
for s = 1 : numel(T1s)
    T1 = T1s{s};
    [p,n] = fileparts(T1);
    subj = strsplit(n,{'.','_'});
    subj = subj{2};
    T2 = dirNii1(fullfile(p, ['erT2_',subj,'*']));
    if isempty(T2), continue; end
    FL = dirNii(fullfile(p, ['erFLAIR_',subj,'*']));
    if isempty(FL), continue; end
    les = dirNii1(fullfile(p, ['srLESION_',subj,'*']));
    if isempty(les), continue; end
    mat = fullfile(p, [n, '.mat']);
    if ~exist(mat,'file'), error('Unable to find %s\n', mat); end
    %fprintf(fid,'%s %s %s %s\n',stripDir(FL{1}),stripDir(T1), stripDir(mat), stripDir(les));
    [~,fl] = fileparts(FL{1});
    seg = strsplit(fl,{'.','_'});
    fl = fl(length(seg{1})+2:end);
    str = sprintf('bianca -v --singlefile=%s --loadclassifierdata=abcx --brainmaskfeaturenum=1 --featuresubset=1,2 --matfeaturenum=3  --trainingpts=2000 --nonlespts=10000 --selectpts=noborder --querysubjectnum=%d -o seg/%s\n', healnm, s, fl);
    fprintf(fid2, str);
end
fclose(fid2);
%fclose(fid);
%end B_enat()

function fnm = stripDir(fnm)
[p,n,x] = fileparts(fnm);
[~,px] = fileparts(p);
fnm = fullfile([ px], [n,x]);
%end stripDir
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


function outniis = nii_copies(fnms, outdir, outnm, copyJsonBvec)
if ~exist(outdir, 'dir'), return; end
if ~exist('copyJsonBvec', 'var'), copyJsonBvec = true; end;
outniis = {};
for i = 1 : numel(fnms)
    fnm = fnms{i};
    outnii = nii_copy(fnm, outdir, outnm, copyJsonBvec);
    outniis = [outniis, {outnii}]
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