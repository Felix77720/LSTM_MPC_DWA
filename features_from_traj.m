function F = features_from_traj(traj)
% features_from_traj - Convert an obstacle trajectory into LSTM input features.
% The heading psi is represented by (cos, sin) to avoid discontinuities at
% +/-pi.
%
% Input:
%   traj - T x 7 obstacle trajectory [x,y,z,vx,vy,vz,psi].
% Output:
%   F - numFeatures x T feature matrix (transposed for convenient windowing).

psi = traj(:, 7);
F = [traj(:, 1:6), cos(psi), sin(psi)]';   % 8 x T
end
