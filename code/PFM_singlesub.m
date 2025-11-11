%% Environment

% add dependencies to Matlab search path
addpath(genpath(['/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/PFM-Tutorial/Utilities']));
addpath(genpath(['/mmfs1/projects/psych_oajilore_chi/mattonim/lld-sal/code/cifti-matlab-master']));
addpath(genpath(['/mmfs1/projects/psych_oajilore_chi/mattonim/lld-sal/code/MSCcodebase-master']));


% define path to some software packages that will be needed
InfoMapBinary = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/Infomap'; 
WorkbenchBinary = '/home/mattonim/workbench/bin_linux64/wb_command'; 

% number of workers
nWorkers = 5;

%% Step 1: Temporal Concatenation of fMRI data from all sessions.

% define subject directory and name;
Subject = '14180';
Subdir = ['/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp/' Subject];


% define & create the pfm directory;
PfmDir = [Subdir '/pfm/'];
%mkdir(PfmDir);
%
%% count the number of imaging sessions;
%nSessions = 1;
%
%% preallocate;
%ConcatenatedData = [];
%
%% sweep through the sessions;
%for i = 1:nSessions
%    
%    % count the number of runs in this session
%    nRuns = length(dir([Subdir '/MNINonLinear/Results/rest*']));
%    
%    % sweep through the runs;
%    for ii = 1:nRuns
%        
%        % load the denoised & fs_lr_32k surface-registered CIFTI file for run "ii" from session "i"...
%        Cifti = ft_read_cifti_mod([Subdir '/MNINonLinear/Results/rest-' num2str(ii) '/rest-' num2str(ii) '_Atlas_s0.dtseries.nii']);
%        Cifti.data = Cifti.data - mean(Cifti.data,2); % demean
%        ConcatenatedData = [ConcatenatedData Cifti.data];
%
%    end
%    
%end
%
%% make a single CIFTI containing time-series from all scans;
%ConcatenatedCifti = Cifti;
%ConcatenatedCifti.data = ConcatenatedData;
%
%
%%% Step 2: Make a distance matrix.
%
%% define fs_lr_32k midthickness surfaces;
MidthickSurfs{1} = [Subdir '/MNINonLinear/fsaverage_LR32k/' Subject '.L.midthickness.32k_fs_LR.surf.gii'];
MidthickSurfs{2} = [Subdir '/MNINonLinear/fsaverage_LR32k/' Subject '.R.midthickness.32k_fs_LR.surf.gii'];
%
%% make the distance matrix;
%pfm_make_dmat(ConcatenatedCifti,MidthickSurfs,PfmDir,nWorkers,WorkbenchBinary); %
%
%% optional: regress adjacent cortical signal from subcortex to reduce artifactual coupling
%% (for example, between cerebellum and visual cortex, or between putamen and insular cortex)
%[ConcatenatedCifti] = pfm_regress_adjacent_cortex(ConcatenatedCifti,[PfmDir '/DistanceMatrix.mat'],20);
%
%% write out the CIFTI file;
%ft_write_cifti_mod([Subdir '/pfm/sub-' Subject '_task-rest_concatenated_32k_fsLR.dtseries.nii'],ConcatenatedCifti);
%
%%% Step 3: Smoothing (Done in ciftify)
%
%%% Step 4: Run infomap.
%
%% load your concatenated resting-state dataset, pick whatever level of spatial smoothing you want
ConcatenatedCifti = ft_read_cifti_mod([PfmDir 'sub-' Subject '_task-rest_concatenated_32k_fsLR.dtseries.nii']);
%
%% define inputs;
%DistanceMatrix = [Subdir '/pfm/DistanceMatrix.mat'];
%DistanceCutoff = 10;
%GraphDensities = flip([0.0001 0.0002 0.0005 0.001 0.002 0.005 0.01 0.02 0.05]);
%NumberReps = 50;
%BadVertices = [];
%Structures = {'CORTEX_LEFT','CEREBELLUM_LEFT','ACCUMBENS_LEFT','CAUDATE_LEFT','PALLIDUM_LEFT','PUTAMEN_LEFT','THALAMUS_LEFT','HIPPOCAMPUS_LEFT','AMYGDALA_LEFT','ACCUMBENS_LEFT','CORTEX_RIGHT','CEREBELLUM_RIGHT','ACCUMBENS_RIGHT','CAUDATE_RIGHT','PALLIDUM_RIGHT','PUTAMEN_RIGHT','THALAMUS_RIGHT','HIPPOCAMPUS_RIGHT','AMYGDALA_RIGHT','ACCUMBENS_RIGHT'};
%
%% run infomap
%pfm_infomap(ConcatenatedCifti,DistanceMatrix,PfmDir,GraphDensities,NumberReps,DistanceCutoff,BadVertices,Structures,nWorkers,InfoMapBinary);
%
%% remove some intermediate files (optional)
%system(['rm ' Subdir '/pfm/*.net']);
%system(['rm ' Subdir '/pfm/*.clu']);
%system(['rm ' Subdir '/pfm/*Log*']);
%
%% define inputs;
%Input = [PfmDir '/Bipartite_PhysicalCommunities.dtseries.nii'];
%Output = 'Bipartite_PhysicalCommunities+SpatialFiltering.dtseries.nii';
%MinSize = 50; % in mm^2
%
%% perform spatial filtering
%pfm_spatial_filtering(Input,PfmDir,Output,MidthickSurfs,MinSize,WorkbenchBinary);

%% Step 5: Algorithmic assignment of network identities to infomap communities.

% Estimate surface areas; 
SurfDir = [Subdir 'MNINonLinear/fsaverage_LR32k'];

% Compute vertex areas for each hemisphere
system(['wb_command -surface-vertex-areas ' SurfDir '/' Subject '.L.midthickness.32k_fs_LR.surf.gii ' SurfDir '/' Subject '.L.midthickness_va.32k_fs_LR.shape.gii']);
system(['wb_command -surface-vertex-areas ' SurfDir '/' Subject '.R.midthickness.32k_fs_LR.surf.gii ' SurfDir '/' Subject '.R.midthickness_va.32k_fs_LR.shape.gii']);

% Merge hemispheres into one dscalar
system(['wb_command -cifti-create-dense-scalar ' SurfDir '/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii ' ...
        '-left-metric ' SurfDir '/' Subject '.L.midthickness_va.32k_fs_LR.shape.gii ' ...
        '-right-metric ' SurfDir '/' Subject '.R.midthickness_va.32k_fs_LR.shape.gii']);



% load the priors;
load('priors.mat');

% define inputs;
Ic = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+SpatialFiltering.dtseries.nii']);
Output = 'Bipartite_PhysicalCommunities+AlgorithmicLabeling';
Column = 6; % column 6, representing graph density 0.01% in this example.

% run the network identification algorithm;
pfm_identify_networks(ConcatenatedCifti,Ic,MidthickSurfs,Column,Priors,Output,PfmDir,WorkbenchBinary);

%% Step 6: Review algorithmic network assignments, optionally adjust labels manually if needed.

% define inputs
XLS = [PfmDir '/Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels+ManualDecisions.xls'];
Output = 'Bipartite_PhysicalCommunities+FinalLabeling';

% OPTIONAL: update network assignments according to manual decisions;
%pfm_parse_manual_decisions(Ic,Column,MidthickSurfs,Priors,XLS,Output,PfmDir,WorkbenchBinary);

%% Step 7: Calculate size of each functional brain network

fprintf('\n==========================================\n');
fprintf('STEP 7: Network Size Calculation\n');
fprintf('==========================================\n');

% define inputs
FunctionalNetworks = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+AlgorithmicLabeling.dlabel.nii']);
VA = ft_read_cifti_mod([Subdir '/fs_LR/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);
Structures = {'CORTEX_LEFT','CORTEX_RIGHT'}; % in this case, cortex only.

% calculate the size of each functional brain network
NetworkSize = pfm_calculate_network_size(FunctionalNetworks,VA,Structures);

% Get unique networks
uCi = unique(nonzeros(FunctionalNetworks.data));

% Print network sizes to console/log
fprintf('\n=== FUNCTIONAL NETWORK SIZES ===\n');
for i = 1:length(uCi)
    fprintf('%s: %.2f%%\n', Priors.NetworkLabels{uCi(i)}, NetworkSize(i));
end
fprintf('=================================\n\n');

% Try to save text file with full debugging
fprintf('DEBUG: Attempting to save text file...\n');
fprintf('DEBUG: PfmDir = "%s"\n', PfmDir);
fprintf('DEBUG: Full path = "%s"\n', [PfmDir '/FunctionalNetworkSizes.txt']);
fprintf('DEBUG: Current directory = "%s"\n', pwd);

% Check if directory is writable
[status, msg] = fileattrib(PfmDir);
if status
    fprintf('DEBUG: Directory exists and is %s\n', msg.UserWrite);
else
    fprintf('DEBUG: Cannot access directory: %s\n', msg);
end

% Try to open file
fid = fopen([PfmDir '/FunctionalNetworkSizes.txt'],'w');
fprintf('DEBUG: fopen returned fid = %d\n', fid);

if fid == -1
    fprintf('ERROR: fopen FAILED to create file!\n');
    [err_msg, err_num] = ferror(fid);
    fprintf('ERROR: ferror returned: %s (error %d)\n', err_msg, err_num);
else
    fprintf('DEBUG: File opened successfully, writing...\n');
    fprintf(fid,'Network\tPercentage\n');
    for i = 1:length(uCi)
        fprintf(fid,'%s\t%.2f\n', Priors.NetworkLabels{uCi(i)}, NetworkSize(i));
    end
    fclose(fid);
    fprintf('DEBUG: Text file written and closed successfully\n');
    
    % Verify file was created
    if exist([PfmDir '/FunctionalNetworkSizes.txt'], 'file')
        fprintf('DEBUG: File verified to exist after writing\n');
    else
        fprintf('ERROR: File does not exist after writing!\n');
    end
end