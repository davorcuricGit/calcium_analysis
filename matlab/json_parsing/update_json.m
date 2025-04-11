
function json = update_json(json, successflag, params)
    params.success = successflag;
    params.name = [params.step '_' params.type '_' json.init.name];
    params.type = params.type;
    params.timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');

    json.(params.step) = params;

end