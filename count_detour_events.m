function [n, events] = count_detour_events(offset, minAmplitude, minDuration, minGap)
% Count sustained, separated lateral excursions using fixed thresholds.
if nargin < 2, minAmplitude = 0.5; end
if nargin < 3, minDuration = 5; end
if nargin < 4, minGap = 10; end
x = abs(offset(:)); active = x >= minAmplitude;
d = diff([false; active; false]); starts=find(d==1); ends=find(d==-1)-1;
% Merge nearby excursions before applying duration, while retaining the
% merged endpoint and requiring a genuine return below threshold.
ms=[]; me=[]; for i=1:numel(starts), if isempty(ms)||starts(i)-me(end)-1>=minGap, ms(end+1)=starts(i); me(end+1)=ends(i); else, me(end)=ends(i); end, end
starts=ms(:); ends=me(:); keep = (ends-starts+1) >= minDuration; starts=starts(keep); ends=ends(keep);
if isempty(starts), n=0; events=zeros(0,3); return; end
n=numel(starts); events=[starts ends zeros(n,1)];
for i=1:n, events(i,3)=max(x(starts(i):ends(i))); end
end
