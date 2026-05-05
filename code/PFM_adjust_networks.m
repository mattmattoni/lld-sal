%% Environment

% add dependencies to Matlab search path
addpath(genpath(['/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/PFM-Tutorial/Utilities']));
addpath(genpath(['/mmfs1/projects/psych_oajilore_chi/mattonim/lld-sal/code/cifti-matlab-master']));
addpath(genpath(['/mmfs1/projects/psych_oajilore_chi/mattonim/lld-sal/code/MSCcodebase-master']));

% define path to software packages
WorkbenchBinary = '/home/mattonim/workbench/bin_linux64/wb_command'; 

% load the priors
load('priors.mat');

%% Step 6: Parse manual decisions and create adjusted network assignments

% define subject directory
Subdir = ['/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp/' Subject];

% define the pfm directory
PfmDir = ['/scratch/network/mattonim/pfm_output/' Subject '/pfm/'];

% define fs_lr_32k midthickness surfaces
MidthickSurfs{1} = [Subdir '/MNINonLinear/fsaverage_LR32k/' Subject '.L.midthickness.32k_fs_LR.surf.gii'];
MidthickSurfs{2} = [Subdir '/MNINonLinear/fsaverage_LR32k/' Subject '.R.midthickness.32k_fs_LR.surf.gii'];

% load infomap communities
Ic = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+SpatialFiltering.dtseries.nii']);

% define inputs for manual decisions
XLS = [PfmDir '/Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels+ManualDecisions.xls'];
Output = 'Bipartite_PhysicalCommunities+AlgorithmicLabeling_adjusted';
Column = 1;

% parse manual decisions and create adjusted network assignments
pfm_parse_manual_decisions(Ic,Column,MidthickSurfs,Priors,XLS,Output,PfmDir,WorkbenchBinary);

%% Step 7: Calculate size of each functional brain network (adjusted version)

% define inputs
FunctionalNetworks = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+AlgorithmicLabeling_adjusted.dlabel.nii']);
VA = ft_read_cifti_mod([Subdir '/MNINonLinear/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);
Structures = {'CORTEX_LEFT','CORTEX_RIGHT'}; % cortex only

% calculate the size of each functional brain network
NetworkSize = pfm_calculate_network_size(FunctionalNetworks,VA,Structures);

% Determine the same indices the function used (subset to requested Structures)
BrainStructure = FunctionalNetworks.brainstructure;
BrainStructure(BrainStructure < 0) = [];
BrainStructureLabels = FunctionalNetworks.brainstructurelabel;
Idx = find(ismember(BrainStructure, find(ismember(BrainStructureLabels, Structures))));

% Compute the unique labels present in that subset
uCi = unique(nonzeros(FunctionalNetworks.data(Idx)));

% Create array of network names and sizes, then sort
NetworkData = cell(length(uCi), 2);
for i = 1:length(uCi)
    % label value (actual label)
    label = uCi(i);

    % safe lookup of name in Priors (fallback if missing)
    if isfield(Priors, 'NetworkLabels') && label <= numel(Priors.NetworkLabels) && ~isempty(Priors.NetworkLabels{label})
        NetworkData{i,1} = Priors.NetworkLabels{label};
    else
        NetworkData{i,1} = sprintf('Label_%d', label);
        warning('No prior label name for label %d — using fallback name.', label);
    end

    % Index by i since NetworkSize corresponds to uCi
    if i <= numel(NetworkSize)
        NetworkData{i,2} = NetworkSize(i);
    else
        NetworkData{i,2} = NaN;
        warning('NetworkSize has no element at index %d (numNetworkSize = %d).', i, numel(NetworkSize));
    end
end

% Sort by network name
NetworkData = sortrows(NetworkData, 1);

% Write to file with _adjusted suffix
fid = fopen([PfmDir '/FunctionalNetworkSizes_adjusted.txt'],'w');
if fid == -1
    error('Could not open %s for writing.', fullfile(PfmDir,'FunctionalNetworkSizes_adjusted.txt'));
end
fprintf(fid,'Network\tPercentage\n');
for i = 1:size(NetworkData, 1)
    if isnan(NetworkData{i,2})
        fprintf(fid,'%s\tNA\n', NetworkData{i,1});
    else
        fprintf(fid,'%s\t%.2f\n', NetworkData{i,1}, NetworkData{i,2});
    end
end
fclose(fid);
fprintf('Wrote %s\n', fullfile(PfmDir,'FunctionalNetworkSizes_adjusted.txt'));

fprintf('[%s] Completed subject: %s\n', datestr(now), Subject);