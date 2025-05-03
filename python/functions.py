import os
import platform
import pandas as pd
import warnings
import numpy as np
import scipy.io
import warnings


def get_computer_alias(computersfile):
    """
    Load computer aliases from CSV and return the alias for the current computer.
    """
    # Load computer aliases from CSV
    data = pd.read_csv(computersfile)  # Assumes columns: RealName, AliasName

    # Get this computer's actual name from environment variable
    real_name = os.environ.get('COMPUTERNAME') or os.environ.get('HOSTNAME')
    
    if not real_name:
        real_name = platform.node()  # platform fallback
    real_name = real_name.strip()

    # Match and retrieve alias (case-insensitive match)
    matches = data[data['RealName'].str.lower() == real_name.lower()]
    
    if not matches.empty:
        alias = matches['AliasName'].iloc[0]
    else:
        warnings.warn(f'Computer name "{real_name}" not found in computers CSV.')
        alias = real_name  # fallback to real name
    
    return alias


def get_needed_derivative(dmeta, subject_json, project):
    derivative_name = dmeta['name']
    derivative_extension = dmeta['derivative_extension']
    file_name = derivative_name + derivative_extension
    format_ = dmeta['format']

    #floc = os.path.join(project['project_root'], project['project_name'], project['structure']['derivatives'], subject_json['init']['raw_path'], file_name)
    floc = os.path.join(project['project_root'],
                        project['project_name'], 
                        project['structure']['derivatives'])
    floc += subject_json['init']['raw_path'] + '/' + file_name
    
    
    
    return new_load_derivative(floc, dmeta)


def new_load_derivative(floc, dmeta):
    derivative = None

    if not os.path.isfile(floc):
        warnings.warn(f"File does not exist: {floc}")
        dmeta['success'] = 0
        return None

    try:
        if dmeta['derivative_extension'] == '.mat':
            S = scipy.io.loadmat(floc, squeeze_me=True, struct_as_record=False)
            if 'derivative' in S:
                derivative = S['derivative']
            else:
                # If there's only one variable, use that
                keys = [k for k in S.keys() if not k.startswith('__')]
                if keys:
                    derivative = S[keys[0]]
                else:
                    raise ValueError("No usable variables found in .mat file")

        elif dmeta['derivative_extension'] == '.csv':
            if dmeta['format'] in ('table', 'struct2table'):
                derivative = pd.read_csv(floc)
            else:
                try:
                    mat = np.loadtxt(floc, delimiter=',')
                    if dmeta['format'] == 'flattened3D':
                        X = int(np.max(mat[:, 0]))
                        Y = int(np.max(mat[:, 1]))
                        Z = int(np.max(mat[:, 2]))
                        reconstructed = np.zeros((X, Y, Z))
                        for row in mat:
                            i, j, k, val = map(int, row[:3]) + [row[3]]
                            reconstructed[i-1, j-1, k-1] = val  # MATLAB is 1-based
                        derivative = reconstructed
                    else:
                        derivative = mat
                except Exception as e:
                    warnings.warn(f"Failed to load CSV as table or matrix: {e}")
                    return None
        else:
            warnings.warn(f"Unsupported file type: {dmeta['derivative_extension']}")
            return None

    except Exception as e:
        warnings.warn(f"Loading failed: {e}")
        dmeta['success'] = 0
        return None

    return derivative
