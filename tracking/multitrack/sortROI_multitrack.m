
function [blob_assigned, blob_permutation, traces_out] = ...
             sortROI_multitrack(traces_out, blob_cen, t_curr, spd_thresh)
%% sort ROIs in multitracking mode
% inputs
%   -> prev_cen:  all trace coords for previous frame of a single ROI
%   -> can_cen:   all blob coords assigned to ROI for current frame


traces_in.t = traces_out.t;
traces_in.cen = traces_out.cen;
trace_permutation = NaN(numel(traces_in.t),1);
blob_permutation = [];

if isempty(traces_in.cen)
    traces_in.cen = zeros(0,1);
end

% define sorting mode
if sum(~isnan(traces_in.cen(:,1))) <= size(blob_cen,1)
    sort_mode = 'trace_sort';
else
    sort_mode = 'blob_sort';
end

switch sort_mode
    case 'trace_sort'
        tar_cen = traces_in.cen;
        can_cen = blob_cen;
        targets_assigned = false(size(tar_cen,1),1);
        trace_updated = targets_assigned;
        candidates_assigned = false(size(can_cen,1),1);
        targets_assigned(isnan(traces_in.cen(:,1))) = true;
        tar_cen(targets_assigned,:) = [];
        blob_assigned = candidates_assigned;
        
    case 'blob_sort'
        tar_cen = blob_cen;
        can_cen = traces_in.cen;
        targets_assigned = false(size(tar_cen,1),1);
        candidates_assigned = false(size(can_cen,1),1);
        trace_updated = candidates_assigned;
        candidates_assigned(isnan(traces_in.cen(:,1))) = true;
        can_cen(candidates_assigned,:) = [];
        blob_assigned = targets_assigned;
end

% exit early if there is nothing to sort
traces_out.updated = trace_updated;
if isempty(tar_cen)
    return;
end

blob_permutation = NaN(numel(traces_in.t),1);

while any(~targets_assigned)
    
    % pairwise distance for each target to the candidates        
    a = repmat(tar_cen,1,1,size(can_cen,1));
    b = permute(repmat(can_cen,1,1,size(tar_cen,1)), [3 2 1]);
    d=abs(sqrt(dot(b-a,a-b,2)));
    
    % get the min distance for each target to closest candidate and return
    % the index of the closest candidate
    [min_dist, match_idx] = min(d,[],3);


    % find candidate indices that are assigned to more than one target
    has_dup = find(histc(match_idx,1:size(can_cen,1))>1);
    no_dup = ~ismember(match_idx,has_dup);
    can_idx = find(~candidates_assigned);
    tar_idx = find(~targets_assigned);

    
    switch sort_mode
        case 'blob_sort'
            traces_out.cen(can_idx(match_idx(no_dup)),:) = tar_cen(no_dup,:);
            traces_in.t(can_idx(match_idx(no_dup))) = t_curr;
            idx = find(isnan(trace_permutation),1);
            idx = idx : idx + numel(can_idx(match_idx(no_dup))) - 1;
            idx(idx>numel(trace_permutation)) = [];
            tmp = can_idx(match_idx(no_dup));
            tmp = tmp(1:numel(idx));
            trace_permutation(idx) = tmp;
            idx = find(isnan(blob_permutation),1);
            idx = idx: idx + numel(tar_idx(no_dup)) - 1;
            idx(idx>numel(blob_permutation)) = [];
            tmp = tar_idx(no_dup);
            tmp = tmp(1:numel(idx));
            blob_permutation(idx) = tmp;
        case 'trace_sort'
            traces_out.cen(tar_idx(no_dup),:) = can_cen(match_idx(no_dup),:);
            traces_in.t(tar_idx(no_dup)) = t_curr;
            idx = find(isnan(trace_permutation),1);
            idx = idx : idx + numel(tar_idx(no_dup)) - 1;
            idx(idx>numel(trace_permutation)) = [];
            tmp = tar_idx(no_dup);
            tmp = tmp(1:numel(idx));
            trace_permutation(idx) = tmp;
            idx = find(isnan(blob_permutation),1);
            idx = idx : idx + numel(can_idx(match_idx(no_dup))) - 1;
            idx(idx>numel(blob_permutation)) = [];
            tmp = can_idx(match_idx(no_dup));
            tmp = tmp(1:numel(idx));
            blob_permutation(idx) = tmp; 
    end

    candidates_assigned(can_idx(match_idx(no_dup))) = true;

    remove_can = match_idx(no_dup);
    idx_shift = sum(repmat(remove_can',size(match_idx,1),1) <...
                    repmat(match_idx,1,size(remove_can,1)),2);
    match_idx = match_idx - idx_shift;
    can_cen(remove_can,:)=[];
    min_dist(no_dup)=[];
    match_idx(no_dup) = [];           
    tar_cen(no_dup,:) = [];
    targets_assigned(tar_idx(no_dup)) = true;
    if all(targets_assigned)
        break;
    end

    % resolve duplicate assignments by finding nearest neighbor
    if ~isempty(has_dup)
        sub_idx = arrayfun(@(idx) find(match_idx==idx),...
                                unique(match_idx),'UniformOutput',false);
        [~,sub_match] = arrayfun(@(idx) min(min_dist(match_idx==idx)),...
                                unique(match_idx));
        best_match = cellfun(@(x,y) x(y), sub_idx, num2cell(sub_match));
        %tmp_match = match_idx+idx_shift(~no_dup);
        can_idx = find(~candidates_assigned);
        tar_idx = find(~targets_assigned);

        switch sort_mode
            case 'blob_sort'
                traces_out.cen(can_idx(best_match),:) = tar_cen(best_match,:);
                traces_in.t(can_idx(best_match)) = t_curr;
                idx = find(isnan(trace_permutation),1);
                idx = idx : idx + numel(can_idx(best_match)) - 1;
                trace_permutation(idx) = can_idx(best_match(1:numel(idx)));
                idx = find(isnan(blob_permutation),1);
                idx = idx : idx + numel(tar_idx(best_match)) - 1;
                blob_permutation(idx) = tar_idx(best_match(1:numel(idx)));
            case 'trace_sort'
                traces_out.cen(tar_idx(best_match),:) = can_cen ...
                                                   (unique(match_idx),:);
                traces_in.t(tar_idx(best_match)) = t_curr;
                idx = find(isnan(trace_permutation),1);
                idx = idx : idx + numel(tar_idx(best_match)) - 1;
                trace_permutation(idx) = tar_idx(best_match(1:numel(idx)));
                idx = find(isnan(blob_permutation),1);
                idx = idx : idx + numel(can_idx(best_match)) - 1;
                blob_permutation(idx) =  can_idx(best_match(1:numel(idx)));
        end

        candidates_assigned(can_idx(best_match)) = true;
        targets_assigned(tar_idx(best_match)) = true;
        can_cen(unique(match_idx),:) = [];
        tar_cen(best_match,:) = [];
    end

end


switch sort_mode
    case 'trace_sort'
        trace_updated = targets_assigned;
        blob_assigned = candidates_assigned;
        
    case 'blob_sort'
        trace_updated = candidates_assigned;
        blob_assigned = targets_assigned;
end

[~,p] = sort(trace_permutation);
blob_permutation = blob_permutation(p);

trace_updated(isnan(traces_out.cen(:,1))) = false;

%% apply speed threshold to centroid tracking
% calculate distance and convert from pix to mm
d = sqrt((traces_out.cen(:,1)-traces_in.cen(:,1)).^2 + ...
         (traces_out.cen(:,2)-traces_in.cen(:,2)).^2);
d = d .* 1;

% time elapsed since each centroid was last updated
dt = t_curr - traces_out.t;

% calculate speed and remove centroids over threshold
spd = d./dt;
above_spd = spd > spd_thresh;
traces_out.cen(above_spd,:) = traces_in.cen(above_spd,:);
traces_out.updated = trace_updated & ~above_spd;
traces_out.t(traces_out.updated,:) = t_curr;
traces_out.speed(traces_out.updated) = spd(traces_out.updated);
blob_permutation(ismember(trace_permutation,find(above_spd))) = [];
blob_permutation(isnan(blob_permutation))=[];
if isempty(blob_permutation)
    blob_permutation = [];
end








