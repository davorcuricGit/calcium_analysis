function [json,ME] = save_derivative(json, derivative, params, project)
ME = [];
try
    % Construct the path
    path = fullfile(project.project_root, project.project_name, project.structure.derivatives, json.init.raw_path);

    % Create folder if it doesn't exist
    if ~isfolder(path)
        mkdir(path)
    end

    % Full location for saving the file
    floc = fullfile(path, [json.(params.step).(params.type).name, params.derivative_extension]);

    % Save as .mat
    if strcmp(params.derivative_extension, '.mat')
        save(floc, 'derivative')
        json.(params.step).(params.type).format = 'matfile';
    % Save as .csv
    elseif strcmp(params.derivative_extension, '.csv')
        if istable(derivative)
            writetable(derivative, floc);
            json.(params.step).(params.type).format = 'table';
        elseif isstruct(derivative)
            try
                T = struct2table(derivative); % Convert struct to table
                writetable(T, floc);
                json.(params.step).(params.type).format = 'struct2table';

            catch
                ME = 'Failed to convert struct to table';
                json.(params.step).success = 0;
                return;
            end

        else % assume matrix
            sz = size(derivative);
            if ndims(derivative) <= 2
                writematrix(derivative, floc);
                json.(params.step).(params.type).format = 'matrix';
            else
                % Flatten 3D+ matrix to 2D with indices
                [xGrid, yGrid, zGrid] = ndgrid(1:sz(1), 1:sz(2), 1:sz(3));
                flat = [xGrid(:), yGrid(:), zGrid(:), derivative(:)];
                writematrix(flat, floc);
                json.(params.step).(params.type).format = 'flattened3D';
            end
        end
        
        json.(params.step).(params.type).success = 1;
        json.(params.step).(params.type).size = size(derivative);
        json.(params.step).(params.type).type = class(derivative);
        

    else
        ME = 'Unknown file type. Only .mat and .csv are supported.';
        json.(params.step).success = 0;
        return;
    end

    % If it succeeded, set success flag
    json.(params.step).success = 1;

catch err
    ME = sprintf('Saving failed: %s', err.message); % include error message
    json.(params.step).success = 0;
end
end
