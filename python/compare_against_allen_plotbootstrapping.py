# requires compare_against_allen_bootstrapping to have been run
from init_analysis import *


#################################gather conditions
conditions = []
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']
    
    # Extract label
    condition = subject_json['init']['condition']
    if 'cohort' in condition:
        condition = re.sub(r'_cohort\d+', '', condition)
    if 'First arm' in condition:
        condition = re.sub('First arm', '', condition)
    if 'Second arm' in condition:
        condition = re.sub('Second arm', '', condition)
    
    conditions.append(condition)
    
    

#######################################################
#######################################################main analysis
#######################################################


#ref = project['reference_condition']
if computer == 'neumann':
    #condition_list = [['Baseline', 'PostShock', 'Post1Hr', 'Post24Hr']]
    condition_list.append(list(set(conditions)))
    #print(condition_list)
    condition_list = my.flatten_list(condition_list)
    #condition_list = list(set(conditions))

else:
    condition_list = list(set(conditions))

dfs = []    
for i,cond in enumerate(condition_list):
    
    load_dir = project['calcium_analysis_root'] 
    load_dir += '/' + 'event_based_networks/python/results/' + computer + '/individual/FCcomparison/' + cond + '/'
    load_dir = my.check_if_dir_exists(load_dir)


    try:
        df = (pd.read_csv(load_dir + 'correlation_table_bootstrap.csv'))
        df['condition'] = cond
        dfs.append(df)
    except:
        continue

df = pd.concat(dfs, ignore_index=True)


##############################################3plopt bootstraps
pairs = df["pair"].unique()
n_pairs = len(pairs)

# Determine subplot layout (e.g., 2 columns)
ncols = 2
nrows = int(np.ceil(n_pairs / ncols))

fig, axes = plt.subplots(nrows, ncols, figsize=(6 * ncols, 8 * nrows), squeeze=False)

for idx, pair in enumerate(pairs):
    ax = axes[idx // ncols, idx % ncols]
    subset = df[df["pair"] == pair]

    # Extract values
    #conditions = subset["condition"]
    #correlations = subset["correlation"]
    #yerr = [subset["error_low"],subset["error_high"]]
    # Group by 'Category' and get mean and standard deviation
    result = subset.groupby('condition').agg(
        mean_value=('correlation', 'mean'),
        std_value=('correlation', 'std')
    ).reset_index()
    
    conditions = list(result['condition'].values)
    correlations = result['mean_value']
    yerr = result['std_value']
   

    # Plot with error bars
    ax.errorbar(
        conditions, correlations, yerr=yerr, fmt='o', capsize=5, linestyle='none'
    )

    ax.set_title(f"Pair: {pair}")
    ax.set_xlabel("Condition")
    ax.set_ylabel("Correlation")
    ax.set_xticks(range(len(conditions)))
    ax.set_xticklabels(conditions, rotation=90)

    
    refcond = project['reference_condition']
    if computer == 'neumann':
        refcond = 'Baseline'
    if 'First arm' in refcond:
        refcond = re.sub('First arm', '', refcond)
    #ch = list(subset[subset['condition'] == refcond]['error_high'])[0]
    #cl = list(subset[subset['condition'] == refcond]['error_low'])[0]
    #c0 = list(result[result['condition'] == refcond]['corr
    cl = list(result[result['condition'] == refcond]['std_value'])[0]
    c0 = list(result[result['condition'] == refcond]['mean_value'])[0]
    ax.axhspan(c0 - cl, c0 + cl, facecolor='yellow', alpha=0.25)

# Hide empty subplots if any
for j in range(idx + 1, nrows * ncols):
    fig.delaxes(axes[j // ncols, j % ncols])

plt.tight_layout()
save_dir = project['calcium_analysis_root'] 
save_dir += '/' + 'event_based_networks/python/results/' + computer + '/individual/FCcomparison/'
plt.savefig(save_dir + 'correlation_comparison.png')
plt.show()