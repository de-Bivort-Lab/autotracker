function getOccupancyHeatmap(expmt,varargin)




%% parse inputs and assign default values

f='centroid';

for i=1:length(varargin)
    arg=varargin{i};
    if ischar(arg)
        switch arg
            case 'Field'
                i=i+1;
                f = varargin{i};
        end
    end
end

bins = linspace(-1,1,12);
binlabels=-1:0.2:1;

%% calculate occupancy

for i=1:expmt.meta.num_traces
    
    f='centroid';
    % normalize centroid to centroid center
    normcen = single(NaN(size(expmt.(f).data(:,:,i))));
    if strcmp(f,'centroid')
        normcen(:,1) = expmt.(f).data(:,1,i) - expmt.meta.roi.centers(i,1);
        normcen(:,2) = expmt.(f).data(:,2,i) - expmt.meta.roi.centers(i,2);
    else
        normcen = expmt.(f).data(:,:,i);
    end
    
    % exclude points that fall outside of the ROI bounds
    exclude = normcen(:,1) < expmt.meta.roi.corners(i,1) - expmt.meta.roi.centers(i,1) |...
        normcen(:,1) > expmt.meta.roi.corners(i,3) - expmt.meta.roi.centers(i,1);
    normcen(exclude,1) = NaN;
    exclude = normcen(:,2) < expmt.meta.roi.corners(i,2) - expmt.meta.roi.centers(i,2) |...
        normcen(:,2) > expmt.meta.roi.corners(i,4) - expmt.meta.roi.centers(i,2);
    normcen(exclude,2) = NaN;
    
    % normalize the range between -1 and 1
    normcen(:,1) =  normcen(:,1)./(expmt.meta.roi.bounds(i,3)/2);
    normcen(:,2) =  normcen(:,2)./(expmt.meta.roi.bounds(i,4)/2);

    % get position histogram
    hmap = NaN(length(bins)-1);
    for j=1:length(bins)-1
        for k=1:length(bins)-1
            
            inx = normcen(:,1) > bins(j) & normcen(:,1) < bins(j+1);
            iny = normcen(:,2) > bins(k) & normcen(:,2) < bins(k+1);
            
            hmap(k,j) = sum(inx & iny);
            
        end
    end
    
    hmap = hmap./sum(hmap(:));
    
    figure();
    subplot(1,3,1);
    plot(normcen(:,1),normcen(:,2),'k');
    hold on
    plot([-1 1],[0 0],'r--','LineWidth',2);
    set(gca,'XLim',[-1 1],'YLim',[-1 1]);
    xlabel('normalized x');
    ylabel('normalized y');
    
    subplot(1,3,2);
    imagesc(hmap);
    set(gca,'XTick',1:length(binlabels),'XTickLabel',binlabels);
    set(gca,'YTick',1:length(binlabels),'YTickLabel',binlabels);
    title('Absolute position');
    xlabel('normalized x');
    ylabel('normalized y');
    colorbar
    
    f='StimCen';
    % normalize centroid to centroid center
    normcen = single(NaN(size(expmt.(f).data(:,:,i))));
    if strcmp(f,'centroid')
        normcen(:,1) = expmt.(f).data(:,1,i) - expmt.meta.roi.centers(i,1);
        normcen(:,2) = expmt.(f).data(:,2,i) - expmt.meta.roi.centers(i,2);
    else
        normcen = expmt.(f).data(:,:,i);
    end
    
    % exclude points that fall outside of the ROI bounds
    exclude = normcen(:,1) < expmt.meta.roi.corners(i,1) - expmt.meta.roi.centers(i,1) |...
        normcen(:,1) > expmt.meta.roi.corners(i,3) - expmt.meta.roi.centers(i,1);
    exclude = exclude | ~expmt.Texture.data;
    normcen(exclude,1) = NaN;
    exclude = normcen(:,2) < expmt.meta.roi.corners(i,2) - expmt.meta.roi.centers(i,2) |...
        normcen(:,2) > expmt.meta.roi.corners(i,4) - expmt.meta.roi.centers(i,2);
    exclude = exclude | ~expmt.Texture.data;
    normcen(exclude,2) = NaN;
    
    % normalize the range between -1 and 1
    normcen(:,1) =  normcen(:,1)./(expmt.meta.roi.bounds(i,3)/2);
    normcen(:,2) =  normcen(:,2)./(expmt.meta.roi.bounds(i,4)/2);

    % get position histogram
    hmap = NaN(length(bins)-1);
    for j=1:length(bins)-1
        for k=1:length(bins)-1
            
            inx = normcen(:,1) > bins(j) & normcen(:,1) < bins(j+1);
            iny = normcen(:,2) > bins(k) & normcen(:,2) < bins(k+1);
            
            hmap(k,j) = sum(inx & iny);
            
        end
    end
    
    hmap = hmap./sum(hmap(:));
    
    subplot(1,3,3);
    imagesc(hmap);
    title('Position relative to stimulus');
    set(gca,'XTick',1:length(binlabels),'XTickLabel',binlabels);
    set(gca,'YTick',1:length(binlabels),'YTickLabel',binlabels);
    colorbar
    xlabel('normalized x');
    ylabel('normalized y');
    
    subplot(1,3,2);
    caxis([0 max(hmap(:))]);
    
    %{
    hmap = hmap./sum(hmap(:));
    %hmap = xc.*yc;
    figure();
    imagesc(hmap);
    colorbar
    %}
    
    
    
end