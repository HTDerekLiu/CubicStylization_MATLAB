function [RAll, objVal, data] = fitRotationL1(U, data)
V = data.V;
F = data.F;
RAll = zeros(3,3,size(V,1)); % all rotation
objVal = 0;

for ii = 1:size(V,1)
    % warm start parameters
    z = data.zAll(:,ii);
    u = data.uAll(:,ii);
    n = data.N(ii,:)';
    rho = data.rhoAll(ii);

    % get geometry params
    hE = data.hEList{ii};
    W = data.WList{ii};
    dV = data.dVList{ii};
    dU = (U(hE(:,2),:) - U(hE(:,1),:))';
    Spre = dV * W * dU';

    % ADMM (maxiter = 100)
    for k = 1:1000
        % R step
        S = Spre + (rho * n * (z-u)');
        R = fit_rotation(S);

        % z step
        zOld = z;
        z = shrinkage(R*n+u, data.lambda*data.VA(ii)/rho);

        % u step
        u = u + R*n - z;

        % compute residual, objective function
        r_norm = norm(z - R*n); % primal
        s_norm = norm(-rho * (z - zOld)); % dual

        % rho step
        if r_norm > data.mu * s_norm
            rho = data.tao * rho;
            u = u / data.tao;
        elseif s_norm > data.mu * r_norm
            rho = rho / data.tao;
            u = u * data.tao;
        end

        % check stopping criteria
        numEle = length(z);
        eps_pri =  sqrt(numEle*2)*data.ABSTOL + data.RELTOL*max(norm(R*n),norm(z));
        eps_dual = sqrt(numEle)*data.ABSTOL + data.RELTOL*norm(rho*u);
        if (r_norm<eps_pri && s_norm<eps_dual)
            % save parameters for future warm start
            data.zAll(:,ii) = z;
            data.uAll(:,ii) = u;
            data.rhoAll(ii) = rho;
            RAll(:,:,ii) = R;

            % save ADMM info
            objVal = objVal + 0.5*sum(sum( ((R*dV-dU)*W*(R*dV-dU)').^2)) + data.lambda* data.VA(ii) * norm(R*n,1);
            break;
        end
    end
end