


function derivative = get_needed_derivative(dmeta, subject_json, project)


derivative_name = dmeta.name;
derivative_extension = dmeta.derivative_extension;
file_name = [derivative_name, derivative_extension];
format = dmeta.format;

floc = fullfile(project.project_root, project.project_name, project.structure.derivatives, subject_json.init.raw_path, file_name);

derivative = new_load_derivative(floc, dmeta);

end

function derivative = new_load_derivative(floc, dmeta)
derivative = [];
ME = [];

try
    % Check if file exists
    if ~isfile(floc)
        ME = 'File does not exist';
        dmeta.success = 0;
        return;
    end

    if strcmp(dmeta.derivative_extension, '.mat')
        S = load(floc); 
        if isfield(S, 'derivative')
            derivative = S.derivative;
        else
            fn = fieldnames(S);
            derivative = S.(fn{1});
        end
        
    
    elseif strcmp(dmeta.derivative_extension, '.csv')
        if strcmp(dmeta.format, 'table') | strcmp(dmeta.format,  'struct2table')

            tbl = readtable(floc);
            derivative = tbl;

        else

            try
                mat = readmatrix(floc);
                if strcmp(dmeta.format, 'flattened3D');
               
                    X = max(mat(:,1));
                    Y = max(mat(:,2));
                    Z = max(mat(:,3));
                    reconstructed = zeros(X, Y, Z);
                    for i = 1:size(mat,1)
                        reconstructed(mat(i,1), mat(i,2), mat(i,3)) = mat(i,4);
                    end
                    derivative = reconstructed;
                else
                    derivative = mat;
                end
            catch
                ME = 'Failed to load CSV as table or matrix';
                return;
            end
        end
    else
        ME = 'Unsupported file type';
        return;
    end

 
catch err
    ME = sprintf('Loading failed: %s', err.message);
    json.(params.step).success = 0;
end
end



