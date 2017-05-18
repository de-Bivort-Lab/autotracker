function analyze_multiFile(funstr,varargin)

    % This script reprocesses the expmt data structs from a user-selected set
    % of files with the function specified by funstr. 

    for i=1:length(varargin)
        if any(strcmp(varargin{i},'Dir')) && strcmp(varargin{i+1},'getdir')
    
            % Get paths to data files
            [fDir] = uigetdir('C:\Users\debivort\Documents\MATLAB\Decathlon Raw Data',...
                'Select directory containing expmt structs to be analyzed');
            
            fPaths = getHiddenMatDir(fDir);
            dir_idx = i+1;
            fDir=cell(size(fPaths));
            for j=1:length(fPaths)
                [tmp_dir,~,~]=fileparts(fPaths{j});
                fDir(j) = {[tmp_dir '\']};
            end
            
        end
    end                         
            

    %% reprocess data
    
    fh = str2func(funstr);
    
    if ~iscell(fPaths)
        fPaths = {fPaths};
    end

    for i=1:length(fPaths)
        disp(['processing file ' num2str(i) ' of ' num2str(length(fPaths))]);
        load(fPaths{i});
        varargin(dir_idx)=fDir(i);
        expmt = feval(fh,expmt,varargin{:});
        clearvars expmt
    end