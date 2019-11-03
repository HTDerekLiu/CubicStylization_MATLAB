clear all; close all;
addpath('./utils')

[V,F] = readOBJ('spot.obj');
nV = size(V,1);

% precomputation
U = V; % output vertex positions
data = precomputation(V,F);
data.lambda = 4e-1; % cubeness

% optimization 
tolerance = 5e-4;
maxIter = 500;
b = 1000; % we have to pin down at least one vertex
bc = U(b,:);

objHis = [];
UHis = zeros(size(V,1), size(V,2), maxIter+1);
UHis(:,:,1) = U;

for iter = 1:maxIter
    
    % local step
    [RAll, objVal, data] = fitRotationL1(U, data);
    
    % save optimization info
    objHis = [objHis objVal];
    UHis(:,:,iter+1) = U; 
    
    % global step
    Rcol = reshape(permute(RAll,[3 1 2]),nV*3*3, 1);
    Bcol = data.K * Rcol;
    B = reshape(Bcol,[size(Bcol,1)/3 3]);
    UPre = U;
    [U,data.preF] = min_quad_with_fixed(data.L/2,B,b,bc,[],[],data.preF);
    
%     % plot
%     if mod(iter-1,1) == 0
%         figure(1)
%         subplot(1,2,1)
%         plotMesh(V,F,[],true);
%         view(0,0)
%         subplot(1,2,2)
%         plotMesh(U,F,[],true);
%         view(0,0)
%         drawnow
%     end
    
    % stopping criteria
    dU = sqrt(sum((U - UPre).^2,2));
    dUV = sqrt(sum((U - V).^2,2));
    reldV = max(dU) / max(dUV);
    fprintf('iter: %d, objective: %d, reldV: %d\n', [iter, objVal, reldV]);
    if reldV < tolerance
        break;
    end
end

outFolder = './results/';
mkdir(outFolder)
for ii = 1:length(objHis)
    meshName = strcat(outFolder,num2str(ii,'%03.f'),'.obj');
    writeOBJ(meshName,UHis(:,:,ii),F);
end