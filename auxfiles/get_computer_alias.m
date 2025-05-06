function alias = get_computer_alias(computersfile)
    % Load computer aliases from CSV
    data = readtable(computersfile);  % Assumes columns: RealName, AliasName

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
        alias = alias(1);  % in case of multiple matches
    else
        warning('Computer name "%s" not found in computers.csv.', realName);
        alias = realName;  % fallback to real name
    end
    alias = char(alias);
end
