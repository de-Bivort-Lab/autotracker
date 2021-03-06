function expmt = editTracesPerROI(expmt, handles)

if ~isfield(expmt.meta.roi,'num_traces')
    expmt.meta.roi.num_traces = ...
        repmat(expmt.parameters.traces_per_roi, expmt.meta.roi.n, 1);
elseif numel(expmt.meta.roi.num_traces) > expmt.meta.roi.n
    expmt.meta.roi.num_traces = ...
        expmt.meta.roi.num_traces(1:expmt.meta.roi.n);
elseif numel(expmt.meta.roi.num_traces) < expmt.meta.roi.n
    expmt.meta.roi.num_traces = ...
        [expmt.meta.roi.num_traces; ...
        repmat(expmt.parameters.traces_per_roi, ...
        expmt.meta.roi.n-numel(expmt.meta.roi.num_traces), 1)];
end


all_obj = findall(handles.axes_handle,'-property','Visible');
is_vis = all_obj(strcmp(get(all_obj,'Visible'),'on'));
set(is_vis,'Visible','off');
handles.hImage = findobj(handles.axes_handle,'-depth',3,'Type','Image');

has_Enable = findall(handles.gui_fig, '-property', 'Enable');
Enable_states = get(has_Enable,'Enable');
on_obj = has_Enable(strcmp(Enable_states,'on'));
set(has_Enable,'Enable','off');

axh = handles.axes_handle;
axh.Visible = 'on';

set(handles.axes_handle,'ButtonDownFcn',@mouse_click_Callback);
handles.hImage.HitTest = 'off';
handles.gui_fig.UserData.edit_rois = true;

% Take single frame
if strcmp(expmt.meta.source,'camera')
    trackDat.im = peekdata(expmt.hardware.cam.vid,1);
else
    [trackDat.im, expmt.meta.video] = nextFrame(expmt.meta.video,handles);
end

% set display to ROI image and label ROIs
handles.hImage.CData = trackDat.im;
handles.hImage.Visible = 'on';
feval(handles.view_roi_bounds_menu.Callback,...
            handles.view_roi_bounds_menu,[]);
cen = expmt.meta.roi.centers;
trackDat.centroid = cen;
ntrace = expmt.meta.roi.num_traces;
th = text(handles.axes_handle, cen(:,1),cen(:,2),...
    '','Color','b','HorizontalAlignment','center','HitTest','off');
arrayfun(@(h,n) updateText(h,n), th, ntrace);

instructions = ...
    {'Left/Right click to add/remove traces in the selected ROI';...
    'Shift-click to increment/decrement in units of 10';
    'Press any key to accept changes and exit'};
hNote = gui_axes_notify(axh, instructions);


while handles.gui_fig.UserData.edit_rois

    pause(0.001);

    % listen for mouse clicks
    if isfield(handles.gui_fig.UserData,'click')
        % get click info
        b = handles.gui_fig.UserData.click.button;
        c = handles.gui_fig.UserData.click.coords;
        
        % find ROI click occured in
        [~,update,~] = sortCentroids(c(1:2), trackDat, expmt);
        roi = find(update,1);

        if ~isempty(roi)
            
            increment = 1;
            if isfield(handles.gui_fig.UserData,'kp') && ...
                    strcmpi(handles.gui_fig.UserData.kp,'shift')
                increment = 10;
            end
            
            % switch left and right click
            switch b                 
                case 1
                    ntrace(roi) = ntrace(roi) + increment;
                case 3
                    ntrace(roi) = ntrace(roi) - increment;
            end
            ntrace(ntrace<0) = 0;
            updateText(th(roi),ntrace(roi));
            
        end

        % remove click data
        handles.gui_fig.UserData = rmfield(handles.gui_fig.UserData,'click');
        handles.gui_fig.UserData.kp = '';
        drawnow limitrate

    end
end

set(is_vis,'Visible','on');
set(on_obj,'Enable','on');
cellfun(@(h) delete(h), hNote);
feval(handles.view_roi_bounds_menu.Callback,...
            handles.view_roi_bounds_menu,[]);
delete(th);
expmt.meta.roi.num_traces = ntrace;
    
    
    
function mouse_click_Callback(hObject,eventdata)

hObject.Parent.UserData.click.button = eventdata.Button;
hObject.Parent.UserData.click.coords = eventdata.IntersectionPoint;

function updateText(th, num)

th.String = num2str(num);