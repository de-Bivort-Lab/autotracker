function [trackDat, expmt, props] = multiTrack(props, trackDat, expmt)

props = erodeDoubleBlobs(props, trackDat);
                
% apply area threshold before assigning centroids
above_min = cat(1,props.Area) .* (expmt.parameters.mm_per_pix^2) > ...
    expmt.parameters.area_min;
props(~above_min,:) = [];

% assign each blob in props to an ROI
raw_cen = cat(1,props.Centroid);
ROI_num = assignROI(raw_cen, expmt);
ROI_num = cat(1,ROI_num{:});
blob_num = 1:size(raw_cen,1);
candidate_ROI_cen = arrayfun(@(x) ...
    raw_cen(ROI_num==x,:), 1:expmt.meta.roi.n, 'UniformOutput',false)';
blob_num = arrayfun(@(x) ...
    blob_num(ROI_num==x), 1:expmt.meta.roi.n, 'UniformOutput',false)';
trackDat.permutation = cell(expmt.meta.roi.n,1);

for i=1:expmt.meta.roi.n
    
[blob_assigned, blob_permutation] = ...
    sortROI_multitrack(trackDat.traces(i), candidate_ROI_cen{i}, ...
        trackDat.t, expmt.parameters.speed_thresh);
    
updateDuration(trackDat.traces(i));
            
trackDat.permutation{i} = blob_num{i}(blob_permutation);

unassigned_blobs = candidate_ROI_cen{i}(~blob_assigned,:);

[blob_assigned, ~] = ...
    sortROI_multitrack(trackDat.candidates(i), unassigned_blobs, ...
        trackDat.t, expmt.parameters.speed_thresh);

updateDuration(trackDat.candidates(i));

new_cen = getNewTraces(unassigned_blobs, ...
    trackDat.candidates(i), blob_assigned, trackDat.t);
              
reviveTrace(trackDat.traces(i), new_cen, trackDat.t);

end   
