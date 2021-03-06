function [histloss, eddyloss, excessloss] = ...
    softferrolossrectregionvarxpartcalc(Bx, By, Bz, kc, kh, ke, beta, xstep, dx, dy, dz)
% part calculates the values of the hysteresis, eddy current and excess
% loss in a cuboidal region of soft ferromagnetic material
%
% Syntax
%
% [histloss, eddyloss, excessloss] = softferrolossrectregpartcalc(Bx, By, Bz, dx, dy, dz, kc, ke, beta)
%
% Input
%
%  Bx - 
% 
%  By - 
% 
%  Bz -  
% 
%  kc -  
% 
%  ke -  
% 
%  beta - 
%
%  dx -  
% 
%  dy -  
% 
%  dz
%
% Output
%
%  histloss -  
% 
%  eddyloss -  
% 
%  excessloss - 
%
% Description
%
% Calculates part of the formula required to perform loss calculations
% using the time-domain method laid out in [1]. The resulting formula
% assumes the direction of motion is constrained so that dB/dt can be
% reasonably represented as:
%
% dB/dx * dx/dt = dB/dx * velocity
%
% [1] D. Lin, P. Zhou, W. N. Fu, Z. Badics, and Z. J. Cendes, â€œA Dynamic
% Core Loss Model for Soft Ferromagnetic and Power Ferrite Materials in
% Transient Finite Element Analysis,ï¿½? IEEE Transactions on Magnetics, vol.
% 40, no. 2, pp. 1318--1321, Mar. 2004.

    if nargin == 9
        dV = dx;
    elseif nargin == 11
        dV = dx .* dy .* dz;
    else
        error('Incorrect number of arguments.')
    end

    % the direction of motion is assumed to be in the x direction. Therfore
    % we first find the derivatives of each B component with respect to
    % this direction. dx is assumed to be a scalar, therefore Bx, By and Bz
    % must all be sampled at
%     dBxVdx = bgrad(Bx, xstep);
%     dByVdx = bgrad(By, xstep);
%     dBzVdx = bgrad(Bz, xstep);
    dBxVdx = gradient(Bx, xstep);
    dByVdx = gradient(By, xstep);
    dBzVdx = gradient(Bz, xstep);
    
    % generate the part calculation of the hysteresis losses for the
    % region, these must be multiplied by the velocity to get the actual
    % losses
    Cbeta = 4 .* quad(@(theta) cos(theta).^beta, 0, pi/2);
    
    Hirrx = hirr_calc(Bx, dBxVdx, beta, kh, Cbeta, 0);
    
    Hirry = hirr_calc(By, dByVdx, beta, kh, Cbeta, 0);
    
    Hirrz = hirr_calc(Bz, dBzVdx, beta, kh, Cbeta, 0);
    
    histloss = abs(Hirrx .* dBxVdx).^(2/beta) ...
               + abs(Hirry .* dByVdx).^(2/beta) ...
               + abs(Hirrz .* dBzVdx).^(2/beta);
        
    histloss = bsxfun(@times, dV, (histloss .^ (beta / 2)));
    
    % sum along the third dimension of the array, this array dimension
    % should correspond to the physical dimension in the y direction
    histloss = sum(histloss, 3);
    
    % sum along the first dimension of the array, this array dimension
    % should correspond to the physical dimension in the x direction
    histloss = sum(histloss, 1);
    
    % generate the part calculation of the eddy current losses for the
    % region, these must be multiplied by the square of the velocity (v^2)
    % to get the actual losses
    Bderivsquares = realpow (dBxVdx, 2) + realpow (dByVdx, 2) + realpow (dBzVdx, 2);
    
    eddyloss =  bsxfun (@times, dV, (kc / (2 * pi^2)) .* Bderivsquares);
    
    eddyloss = sum (eddyloss, 3);
    
    eddyloss = sum (eddyloss, 1);
    
    % generate the part calculation of the excess (sometimes innacurately
    % known as anomalous) losses for the region, these must be multiplied
    % by the cube of the square root of the velocity (sqrt(v)^3) to get the
    % actual losses
    
    % Ce is a constant found by the numerical solution of 
    % <latex>
    % \[ Ce = (2*\pi)^{1.5} \frac{2}{\pi} \int_{0}^{\frac{\pi}{2}} \cos^{1.5}(\theta) d \theta \]
    % <latex>
    % This is described in [1]
    Ce = 8.763363;
    
    excessloss = bsxfun (@times, dV, (ke / Ce) .*  realpow(Bderivsquares, 0.75));
    
    excessloss = sum (excessloss, 3);
    
    excessloss = sum (excessloss, 1);

end


% function Hirr = hirr_calc(B, dBVdx, beta, kh, Cbeta, Bdc)
% % calcualtes the irreversible component of magnetisation in a material
% %
% % Syntax
% %
% % Hirr = hirr_calc(B, beta, kh, Cbeta)
% %
% % Input
% % 
% % 
% 
%     if every(dBVdx == 0)
%         Hirr = zeros (size (B));
%     else
%     
% %     % check for any dc component to the time varying field
% %     Bdc = mean(B,2);
%     
%         Bac = bsxfun(@minus, B, Bdc);
% 
% %    Bac = B;
%     
%         Bm = max(abs(Bac),[],2);
%     
%         % determine the angle of the EEL elipse
%         xtheta = bsxfun(@rdivide, Bac, Bm);
%     
%         % estimate Hirr
%         Hirr = abs( (kh ./ Cbeta) .* abs( bsxfun(@times, cos(asin(xtheta)), Bm) ).^(beta - 1) );
%     
%         Hirr (isnan (Hirr)) = 0;
%     end
%     
% end


function Bgrad = bgrad(Bmat, xstep)

    if isscalar(xstep)
        xstep = 0:xstep:(xstep*(size(Bmat, 2)-1));
    end
    
    % switch the rows with the columns as interp1, which we will use to
    % generate a piecewise polynomial fitted to the data, interpolates down
    % the first dimension of the matrix (the rows), but the data is
    % provided with x along the 2nd dimenaion, (the columns). This is
    % identical to doing the transpose of each slice of the 3D matrix in
    % the 3rd dimension
    Bmat = permute(Bmat,[2,1,3]);
    
    % generate the piecewise polynomial fits to the data using interp1
    pp = interp1(xstep.', Bmat, 'pchip', 'pp');
    
    % now construct a new set of polynomials which are the derivatives of
    % the originals
    [breaks,coefs,~,order,targetdim] = unmkpp(pp);
    
    % make the polynomials that describe the derivatives
    dpp = mkpp(breaks, bsxfun(@times, coefs(:,1:order-1), order-1:-1:1), targetdim);
    
    % record that the input data was oriented according to INTERP1's rules.
    % Thus PPVAL will return its values oriented according to INTERP1's
    % convention
    dpp.orient = 'first';
    
    % calculate the gradients using these new polynomials
    Bgrad = ppval(dpp, xstep);
    
    % inverse permute to get the original direction
    Bgrad = ipermute(Bgrad, [2,1,3]);

end


function Hirr = hirr_calc(B, dBVdx, beta, kh, Cbeta, Bdc)
% calcualtes the irreversible component of magnetisation in a material

% 
% When Bm is determined, theta is a function of B: theta = arcsin(B / Bm)
% which is ranging from -pi/2 to pi/2, and is corresponding to the right
% half ellipse for increasing B. When B is decreasing, theta is ranging
% from pi/2 to 3*pi/2.
% 
% If B has a DC component Bdc, then
% B = Bdc + Bm*sin(theta)
% and therefore,
% theta = arcsin((B-Bdc) / Bm)
% where Bm = (Bmax - Bmin) / 2, Bdc = (Bmax + Bmin) / 2.
    
    if every(dBVdx == 0)
        Hirr = zeros(size(B));
    else
        
        if nargin < 6
            % check for any dc component to the time varying field
            Bdc = mean(B,2);
        end
    
        % remove the dc component
        Bnorm = bsxfun(@minus, B, Bdc);

        % get the magnitude of the variation in the field
        Bm = max(Bnorm,[],2);

        % determine the angle of the EEL elipse
        xtheta = bsxfun(@rdivide, Bnorm, Bm);

        xtheta(dBVdx >= 0) = asin(xtheta(dBVdx >= 0));
        xtheta(dBVdx < 0) = tau/2 - asin(xtheta(dBVdx < 0));

        % estimate Hirr
        Hirr = abs( (kh ./ Cbeta) .* abs( bsxfun(@times, Bm, cos(xtheta)) ).^(beta - 1) );
        
    end
    
end
