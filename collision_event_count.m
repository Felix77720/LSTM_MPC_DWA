function n = collision_event_count(clearance, threshold)
% collision_event_count - Count sustained threshold crossings, not samples.
if nargin < 2, threshold = 0; end
hit = clearance(:) < threshold;
n = sum(hit & [true; ~hit(1:end-1)]);
end
