function [alias,projectsDir] = get_computer_alias(computersfile)
    % Load computer aliases from CSV
    data = readtable(computersfile);  % Assumes columns: RealName, AliasName, projectsDir

    % Get this computer's actual name from environment variable

    realName = getenv('COMPUTERNAME');
    if realName == ""
        realName = getenv('HOSTNAME');  % for compatibility with Unix/Mac
    end
    if realName == ""
        [ret, realName] = system('hostname');
    end

    realName = strtrim(realName);
    % Match and retrieve alias
    match = strcmpi(data.RealName, realName);
    
    if any(match)
        alias = data.AliasName(match);
        alias = char(alias(1));  % in case of multiple matches
        projectsDir = char(data.projectsDir(match));
    else
        warning('Computer name "%s" not found in computers.csv.', realName);
        alias = char(realName);  % fallback to real name
        projectsDir = [];
    end
    alias = char(alias);
end
