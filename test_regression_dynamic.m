function test_regression_dynamic()
% Deterministic, dependency-free checks for time alignment and event metrics.
assert(collision_event_count([1 1 1]) == 0);
assert(collision_event_count([-1 -1 -1]) == 1);
assert(collision_event_count([1 -1 -1 1 -1]) == 2);
assert(count_detour_events(zeros(20,1), 0.25, 2, 3) == 0);
wave = [zeros(3,1); ones(3,1); zeros(3,1); -ones(3,1); zeros(3,1); ones(3,1); zeros(3,1)];
assert(count_detour_events(wave, 0.25, 2, 3) == 3);
assert(count_detour_events([ones(5,1); zeros(9,1); ones(5,1)],0.5,5,10)==1);
assert(count_detour_events([ones(5,1); zeros(10,1); ones(5,1)],0.5,5,10)==2);
fprintf('dynamic regression tests passed\n');
end
