function [trackDat, expmt, props] = multiTrack(props, trackDat, expmt)

t1=toc;
props = erodeDoubleBlobs(props, trackDat);
                
% apply area threshold before assigning centroids
above_min = cat(1,props.Area) .* (expmt.parameters.mm_per_pix^2) > ...
    expmt.parameters.area_min;
props(~above_min,:) = [];

% assign each blob in props to an ROI
[candidate_ROI_cen, blob_num] = assignROI(cat(1,props.Centroid), expmt);


blob_assigned = cell(expmt.meta.roi.n,1);
blob_permutation = cell(expmt.meta.roi.n,1);
for i=1:expmt.meta.roi.n
    [blob_assigned{i}, blob_permutation{i}] = ...
        sortROI_multitrack(trackDat.traces(i), candidate_ROI_cen(i), ...
            trackDat.t, expmt.parameters.speed_thresh);
end   

            
arrayfun(@(t) updateDuration(t), trackDat.traces);
            
trackDat.permutation = cellfun(@(bn,bp) bn(bp), blob_num, blob_permutation,...
                    'UniformOutput',false);
                

unassigned_blobs = cellfun(@(cr,ba) cr(~ba,:), candidate_ROI_cen, ... 
                       blob_assigned, 'UniformOutput', false);
%add_nums = cellfun(@(ba) find(~ba), blob_assigned, 'UniformOutput', false);

[blob_assigned, ~] = ...
    arrayfun(@(trace, blob) sortROI_multitrack(trace, blob, ...
        trackDat.t, expmt.parameters.speed_thresh), ...
        trackDat.candidates, unassigned_blobs,'UniformOutput', false);  
    


arrayfun(@(t) updateDuration(t), trackDat.candidates);

new_cen = arrayfun(@(ub, can, ba) getNewTraces(ub, can, ba, trackDat.t),...
    unassigned_blobs, trackDat.candidates, blob_assigned,...
    'UniformOutput', false);
              

arrayfun(@(trace, cen) ...
    reviveTrace(trace, cen, trackDat.t), trackDat.traces, new_cen);
      
t2=toc;
fprintf('%0.2f\n',(t2-t1)*1000);
