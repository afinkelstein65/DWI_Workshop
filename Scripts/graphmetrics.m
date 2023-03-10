%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Graph Theory Analysis of Structural Connectivity Matrix 
% Weighted Undirected Matrix 
%
% Author: Alan Finkelstein
% Date: February, 2023
%
% Outputs graph theory metrics in table format. 
% GRAPHMETRICS calculate graph theory metrics
%
%   GRAPHMETRICS(conmat, outdir, fileprefix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Need to clean up code and comment better. 
function graphmetrics(conmat, outdir, fileprefix)

% Updated with wherever BCT is saved
addpath("/Users/afinkelstein/BCT/2019_03_03_BCT/")

disp(conmat) 
conmat = load(conmat).conmat;
conmat_nrm = threshold_proportional(conmat,.03);
conmat_nrm = weight_conversion(conmat_nrm, 'binarize');

% Normalize Matrix
% conmat(conmat > 100) = 0;



% ass = assortativity_bin(conmat)
% mod = modularity_und(conmat_nrm);
% disp(mod)
% disp(ass)

% conmat_nrm = weight_conversion(conmat,'binarize'); 
% ass = assortativity_bin(conmat_nrm,0);
% trans = transitivity_bu(conmat_nrm);
% disp(trans)
% disp(ass)
% 
transitivities = []; 
associativities =[]; 
for i = 0.5:-0.01:0.01
   
%     conmat_nrm = weight_conversion(conmat,'binarize'); 
    conmat = threshold_proportional(conmat,i);
    conmat = weight_conversion(conmat,'binarize');
    
    
    trans = transitivity_bu(conmat);
    ass = assortativity_bin(conmat,0); 
    transitivities = [transitivities; trans];
    associativities = [associativities; ass]; 

end 
% 
figure 
plot(flip(transitivities)); title('Transitivity'); 
figure(); 
plot(flip(associativities));
title('Associativity')
disp(transitivities)

% mod = modularity_und(conmat_nrm);


% Normalize matrix
figure; 
imagesc(conmat_nrm); 
% set(gca, 'clim',[0, 250]); 
colorbar; 
colormap 'jet';


end 