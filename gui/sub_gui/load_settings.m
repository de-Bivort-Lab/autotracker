function expmt_old = load_settings(expmt_old, expmt_new, handles)

% update tracking parameters and related gui objects
handles.gui_fig.UserData.speed_thresh = expmt_old.parameters.speed_thresh;
handles.gui_fig.UserData.distance_thresh = expmt_old.parameters.distance_thresh;
handles.gui_fig.UserData.vignette_sigma = expmt_old.parameters.vignette_sigma ;
handles.gui_fig.UserData.vignette_weight = expmt_old.parameters.vignette_weight;
handles.gui_fig.UserData.area_min = expmt_old.parameters.area_min;
handles.gui_fig.UserData.area_max = expmt_old.parameters.area_max;
handles.edit_ref_depth.Value = expmt_old.parameters.ref_depth;
handles.edit_ref_depth.String = num2str(expmt_old.parameters.ref_depth);
handles.edit_ref_freq.Value = expmt_old.parameters.ref_freq;
handles.edit_ref_freq.String = num2str(expmt_old.parameters.ref_freq);
handles.edit_exp_duration.Value = expmt_old.parameters.duration;
handles.edit_exp_duration.String = num2str(expmt_old.parameters.duration);
handles.ROI_thresh_slider.Value = expmt_old.parameters.ROI_thresh;
handles.disp_ROI_thresh.String = num2str(round(expmt_old.parameters.ROI_thresh));
handles.track_thresh_slider.Value = expmt_old.parameters.track_thresh;
handles.disp_track_thresh.String = num2str(round(expmt_old.parameters.track_thresh));
handles.save_path.String = expmt_old.fpath;

% update experiment selection
if isfield(expmt_old,'Name')
    exp_names = handles.exp_select_popupmenu.String;
    for i = 1:length(exp_names)
        if strcmp(expmt_old.Name,exp_names{i})
            handles.exp_select_popupmenu.Value = i;
            expmt_old.expID = i;
        end
    end
end

if ~isfield(expmt_old,'expID')
    expmt_old.expID = 1;
end

% update video/camera source
switch expmt_old.source
    
    case 'camera'
        handles.time_remaining_text.String = 'time remaining';
        handles.edit_time_remaining.String = '00:00:00';

        if strcmp(handles.cam_uipanel.Visible,'off')
            handles.cam_uipanel.Visible = 'on';
        end

        if strcmp(handles.vid_uipanel.Visible,'on')
            handles.vid_uipanel.Visible = 'off';
        end
        
    case 'video'
        handles.time_remaining_text.String = 'frames remaining';
        handles.edit_time_remaining.String = '-';

        if strcmp(handles.vid_uipanel.Visible,'off')
            handles.vid_uipanel.Visible = 'on';
            handles.vid_uipanel.Position = handles.cam_uipanel.Position;
        end

        if strcmp(handles.cam_uipanel.Visible,'on')
            handles.cam_uipanel.Visible = 'off';
        end
end

% assign current values for hardware settings
expmt_old.COM = expmt_new.COM;

if ~isempty(expmt_new.camInfo.DeviceInfo)
    if strcmp(expmt_old.camInfo.DeviceInfo.DeviceName,expmt_new.camInfo.DeviceInfo.DeviceName)

        % stop and delete existing vid object
        if isfield(expmt_new.camInfo,'vid')
            delete(expmt_new.camInfo.vid);
            imaqreset;
        end

        % update camera dropdown menu
        for i = 1:length(handles.cam_list)
            if strcmp(expmt_old.camInfo.DeviceInfo.DeviceName,handles.cam_list(i).name)
                handles.cam_select_popupmenu.Value = i;
            end
        end

        % update camera mode dropdown
        handles.cam_mode_popupmenu.String = expmt_old.camInfo.DeviceInfo.SupportedFormats;
        for i = 1:length(handles.cam_mode_popupmenu.String)
            if strcmp(handles.cam_mode_popupmenu.String{i},expmt_old.camInfo.ActiveMode{:})
                handles.cam_mode_popupmenu.Value = i;
            end
        end

    else
        expmt_old.camInfo = expmt_new.camInfo;
    end
else
    expmt_old.camInfo = expmt_new.camInfo;
end

% remove fields that must be re-defined each expmt
if isfield(expmt_old,'ROI')
    expmt_old = rmfield(expmt_old,'ROI');
end

if isfield(expmt_old,'noise')
    expmt_old = rmfield(expmt_old,'noise');
end

if isfield(expmt_old,'ref')
    expmt_old = rmfield(expmt_old,'ref');
end

if isfield(expmt_old.vignette,'im')
    expmt_old.vignette = rmfield(expmt_old.vignette, 'im');
end

%% update gui enable states

% handles.run_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');

switch expmt_old.source
    case 'camera'

        % set all downstream panels to disabled until cam settings are confirmed
        handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.run_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
        
    case 'video'
        
        % disable all downstream panels
        handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.run_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
        
        % enable ROI detection controls if video object exists
        if isfield(expmt_old,'video')
            handles.ROI_thresh_slider.Enable = 'on';
            handles.accept_ROI_thresh_pushbutton.Enable = 'on';
            handles.disp_ROI_thresh.Enable = 'on';
            handles.auto_detect_ROIs_pushbutton.Enable = 'on';
            handles.text_object_num.Enable = 'on';
            handles.edit_object_num.Enable = 'on';
        end         
        
end

