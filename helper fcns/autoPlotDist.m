function [fig_handle, varargout] = autoPlotDist(data, filter, varargin)

ah = [];
for i=1:numel(varargin)
    if ishghandle(varargin{i}) && strcmpi(varargin{i}.Type,'axes')
        hold on;
        ah = varargin{i};
    end
end

if ~isempty(ah)
    fh = ah.Parent;
else
    fh = figure();
end

% Histogram for stimulus ON period
if min(data) > 0
    bins = 0:0.1:1;
else
    bins = -1:0.2:1;
end

data = data(filter,:);
[kde, x] = ksdensity(data);

lh = plot(x, kde,'Linewidth',2);
set(gca, 'Xtick',bins, 'XLim', [bins(1) bins(end)],...
    'Ylim', [0 max(kde)*1.1], 'TickLength', [0 0]);
% add bs and obs patch
vx = [x x(end) x(1)];
vy = [kde 0 kde(1)];
ph = patch(vx,vy,lh.Color,'FaceAlpha',0.3);
uistack(ph,'bottom');
fig_handle = fh;
hold off;