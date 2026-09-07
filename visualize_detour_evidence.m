function visualize_detour_evidence(res,noobs,cfg,outdir,outputTag)
if nargin<4, outdir=fullfile(fileparts(mfilename('fullpath')),'results'); end; if ~exist(outdir,'dir'),mkdir(outdir);end
if nargin<5, outputTag=''; end
t=res.time(2:end); t=t(:); n=numel(res.horizontalOffset); t=t(1:n); [ne,ev]=count_detour_events(res.horizontalOffset);
f=figure('Visible','off','Color','w','Position',[50 50 1400 1000]); tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
ax1=nexttile; hold on; h=[]; names={}; h(end+1)=plot3(res.traj(:,1),res.traj(:,2),res.traj(:,3),'b','LineWidth',2); names{end+1}='ego';
if isfield(noobs,'traj'), h(end+1)=plot3(noobs.traj(:,1),noobs.traj(:,2),noobs.traj(:,3),'--','Color',[.55 .55 .55]); names{end+1}='no-obstacle'; end
h(end+1)=plot3([res.start(1) res.goal(1)],[res.start(2) res.goal(2)],[res.start(3) res.goal(3)],'k:'); names{end+1}='start-goal line'; cc=lines(max(1,numel(res.obstacles)));
for j=1:numel(res.obstacles),q=res.obstacles(j).traj;h(end+1)=plot3(q(:,1),q(:,2),q(:,3),'Color',cc(j,:));names{end+1}=sprintf('obstacle %d',j); [~,ix]=min(vecnorm(q(1:min(size(q,1),size(res.traj,1)),1:3)-res.traj(1:min(size(q,1),size(res.traj,1)),1:3),2,2)); [sx,sy,sz]=sphere(20); surf(res.obstacles(j).radius*sx+q(ix,1),res.obstacles(j).radius*sy+q(ix,2),res.obstacles(j).radius*sz+q(ix,3),'FaceColor',cc(j,:),'FaceAlpha',.15,'EdgeColor','none','HandleVisibility','off'); end
plot3(res.start(1),res.start(2),res.start(3),'ko','MarkerFaceColor','k');plot3(res.goal(1),res.goal(2),res.goal(3),'ks','MarkerFaceColor','k');view(40,25);axis tight;xlabel X;ylabel Y;zlabel Z;title(sprintf('3-D truth | success=%d, collisions=%d, detours=%d',res.success,res.collisionEvents,ne));legend(h,names,'Location','best','Color','w','TextColor','k');
ax2=nexttile;hold on;plot(res.alongTrack,res.horizontalOffset,'b','LineWidth',1.5);yline(0,'k:');yline(.5,'r--');yline(-.5,'r--');xlabel('Along-track s (m)');ylabel('Signed lateral offset (m)');title('Along-track evidence');
ax3=nexttile;hold on;plot(t,res.horizontalOffset,'b','LineWidth',1.4);plot(t,res.verticalOffset,'m','LineWidth',1.4);yline(.5,'r--');yline(-.5,'r--');xlabel('Time (s)');ylabel('Offset (m)');title('Signed offsets');legend('lateral','vertical','threshold','Color','w','TextColor','k');
ax4=nexttile;plot(t,res.stepClearance,'r','LineWidth',1.4);hold on;yline(0,'k:');xlabel('Time (s)');ylabel('True clearance (m)');title('True clearance');
for i=1:size(ev,1),a=res.alongTrack(ev(i,1));b=res.alongTrack(min(ev(i,2),n));yl=ylim(ax2);patch(ax2,[a b b a],[yl(1) yl(1) yl(2) yl(2)],[.95 .85 .55],'FaceAlpha',.18,'EdgeColor','none','HandleVisibility','off');a=t(ev(i,1));b=t(min(ev(i,2),n));for ax=[ax3 ax4],yl=ylim(ax);patch(ax,[a b b a],[yl(1) yl(1) yl(2) yl(2)],[.95 .85 .55],'FaceAlpha',.18,'EdgeColor','none','HandleVisibility','off');end,end
for ax=[ax1 ax2 ax3 ax4],set(ax,'Color','w','XColor','k','YColor','k','ZColor','k','FontSize',11,'TitleFontSizeMultiplier',1);grid(ax,'on');ax.Title.Color='k';end
set(findall(f,'Type','text'),'Color','k');
if isempty(outputTag)
    tag=res.method;if isfield(res,'routeWeight'),tag=sprintf('%s_w%d',tag,res.routeWeight);end
else
    tag=outputTag;
end
exportgraphics(f,fullfile(outdir,[tag '.png']),'Resolution',300);exportgraphics(f,fullfile(outdir,[tag '.pdf']),'ContentType','vector');close(f);
end
