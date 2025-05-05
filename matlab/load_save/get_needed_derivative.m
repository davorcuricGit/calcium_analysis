


function [derivative, ME] = get_needed_derivative(dmeta, subject_json, project)
ME = [];
try 
derivative_name = dmeta.name;
derivative_extension = dmeta.derivative_extension;
file_name = [strrep(derivative_name, derivative_extension, ''), derivative_extension];
format = dmeta.format;

floc = fullfile(project.project_root, project.project_name, project.structure.derivatives, subject_json.init.raw_path, file_name);

[derivative,ME] = new_load_derivative(floc, dmeta);
catch ME
end

end




