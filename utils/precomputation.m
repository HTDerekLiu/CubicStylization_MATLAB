function data = precomputation(V,F)
    data.V = V;
    data.F = F;
    data.N = per_vertex_normals(V,F); % input vertex normal
    data.L = cotmatrix(V,F); % cotangent 
    data.VA = full(diag(massmatrix(V,F))); % vertex area
    
    % ARAP precomputation
    data.preF = []; % prefactorization of L
    adjFList = vertexFaceAdjacencyList(F); % vertex adjacency list
    [~,data.K] = arap_rhs(V,F,[],'Energy','spokes-and-rims');
    data.hEList = cell(size(V,1),1);
    data.WList = cell(size(V,1),1);
    data.dVList = cell(size(V,1),1);
    for ii = 1:size(V,1)
        adjF = adjFList{ii};
        hE = [F(adjF,1) F(adjF,2); ...
              F(adjF,2) F(adjF,3); ...
              F(adjF,3) F(adjF,1)];
        idx = sub2ind(size(data.L), hE(:,1), hE(:,2));
        
        data.hEList{ii} = hE;
        data.WList{ii} = diag(full(data.L(idx)));
        data.dVList{ii} = (V(hE(:,2),:) - V(hE(:,1),:))';
    end
    
    % local step parameters
    data.rho = 1e-4;
    data.ABSTOL = 1e-5;
    data.RELTOL = 1e-3;
    data.mu = 5;
    data.tao = 2; 
    data.maxIter_ADMM = 100;
    data.objVal = 0;
    data.zAll = zeros(3,size(V,1));
    data.uAll = zeros(3,size(V,1));
    data.rhoAll = data.rho * ones(size(V,1),1);
    
end
