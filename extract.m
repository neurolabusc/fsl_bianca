function extract(fnms)
t1 = fnms{1};
newSegSub(t1)
extractSub(0.3, fnms);

function extractSub(thresh, fnms)
%subroutine to extract brain from surrounding scalp
% fnms: images to be extracted, first must be T1
% c1: gray matter map
% c2: white matter map
% c3: [optional] spinal fluid map
t1 = fnms{1};
fprintf('Brain extraction of %s\n', t1);
[pth,nam,ext] = spm_fileparts(t1);
c1 = fullfile(pth, ['c1', nam, ext]);
c2 = fullfile(pth, ['c2', nam, ext]);
c3 = fullfile(pth, ['c3', nam, ext]);
%load headers
gi = spm_vol(c1);%Gray Matter map
wi = spm_vol(c2);%White Matter map
%load images
g = spm_read_vols(gi);
w = spm_read_vols(wi);
ci = spm_vol(c3);%CSF map
c = spm_read_vols(ci);
w = c+w;
w = g+w;

mask= zeros(size(w));
mask(w >= thresh) = 255;
spm_smooth(mask,mask,1); %feather the edges
mask = mask / 255;
%
for i = 1 : numel(fnms)
    t1 = fnms{i};
    [pth,nam,ext] = spm_fileparts(t1);
    mi = spm_vol(t1);%bias corrected T1
    m = spm_read_vols(mi);
    m=m.*mask;
    %mi.fname = fullfile(pth,['b',  nam, ext]);
    %mi.dt(1) = 4; %16-bit precision more than sufficient uint8=2; int16=4; int32=8; float32=16; float64=64
    spm_write_vol(mi,m);
    %t1Bet = mi.fname;
end
%end extractSub()

function newSegSub(t1)
%apply new segment - return name of warping matrix
template = fullfile(spm('Dir'),'tpm','TPM.nii');
fprintf('NewSegment of %s\n', t1);
matlabbatch{1}.spm.spatial.preproc.channel(1).vols = {t1};
matlabbatch{1}.spm.spatial.preproc.channel(1).biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel(1).biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel(1).write = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[template ',1']};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[template ',2']};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[template ',3']};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[template ',4']};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[template ',5']};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[template ',6']};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];
spm_jobman('run',matlabbatch);
%end newSegSub()