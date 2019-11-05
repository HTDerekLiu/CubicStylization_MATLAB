function [RAll, objVal, rotData] = fitRotationL1(U, rotData)
%{
    FITROTATIONL1 solves the following problem
    for each vertex i
    Ri <- argmin Wi/2*||Ri*dVi - dUi||^2_F + lambda*VAi*|| Ri*ni||_1
    where R is a rotation matrix
    
    Reference:
    Liu & Jacobson, "Cubic Stylization", 2019 (Section 3.1)
%}

nV = size(U,1);
RAll = zeros(3,3,nV); % all rotation
objVal = 0;

% initialization (warm start for consecutive iterations)
if ~isfield(rotData, 'zAll')
    rotData.zAll = zeros(3,nV);
    rotData.uAll = zeros(3,nV);
    rotData.rhoAll = rotData.rho * ones(nV,1);
    
    adjFList = vertexFaceAdjacencyList(rotData.F);
    rotData.hEList = cell(nV,1); % half edge lise
    rotData.WList = cell(nV,1); % wieght matrix W
    rotData.dVList = cell(nV,1); % dV spokes and rims
    for ii = 1:nV
        adjF = adjFList{ii};
        hE = [rotData.F(adjF,1) rotData.F(adjF,2); ...
              rotData.F(adjF,2) rotData.F(adjF,3); ...
              rotData.F(adjF,3) rotData.F(adjF,1)];
        idx = sub2ind(size(rotData.L), hE(:,1), hE(:,2));
        
        rotData.hEList{ii} = hE;
        rotData.WList{ii} = diag(full(rotData.L(idx)));
        rotData.dVList{ii} = (rotData.V(hE(:,2),:) - rotData.V(hE(:,1),:))';
    end
end

% start rotation fitting with ADMM
for ii = 1:nV
    % warm start parameters
    z = rotData.zAll(:,ii);
    u = rotData.uAll(:,ii);
    n = rotData.N(ii,:)';
    rho = rotData.rhoAll(ii);

    % get geometry params
    hE = rotData.hEList{ii};
    W = rotData.WList{ii};
    dV = rotData.dVList{ii};
    dU = (U(hE(:,2),:) - U(hE(:,1),:))';
    Spre = dV * W * dU';

    % ADMM
    for k = 1:rotData.maxIter_ADMM
        % R step
        S = Spre + (rho * n * (z-u)');
        R = fit_rotation(S);

        % z step
        zOld = z;
        z = shrinkage(R*n+u, rotData.lambda*rotData.VA(ii)/rho);

        % u step
        u = u + R*n - z;

        % compute residual, objective function
        r_norm = norm(z - R*n); % primal
        s_norm = norm(-rho * (z - zOld)); % dual

        % rho step
        if r_norm > rotData.mu * s_norm
            rho = rotData.tao * rho;
            u = u / rotData.tao;
        elseif s_norm > rotData.mu * r_norm
            rho = rho / rotData.tao;
            u = u * rotData.tao;
        end

        % check stopping criteria
        numEle = length(z);
        eps_pri =  sqrt(numEle*2)*rotData.ABSTOL + rotData.RELTOL*max(norm(R*n),norm(z));
        eps_dual = sqrt(numEle)*rotData.ABSTOL + rotData.RELTOL*norm(rho*u);
        if (r_norm<eps_pri && s_norm<eps_dual)
            % save parameters for future warm start
            rotData.zAll(:,ii) = z;
            rotData.uAll(:,ii) = u;
            rotData.rhoAll(ii) = rho;
            RAll(:,:,ii) = R;

            % save ADMM info
            objVal = objVal + 0.5*sum(sum( ((R*dV-dU)*W*(R*dV-dU)').^2)) + rotData.lambda* rotData.VA(ii) * norm(R*n,1);
            break;
        end
    end
end