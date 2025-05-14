#requires nodes and edges file (step2)
from init_analysis import *
import seaborn as sns

with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

edge_df = pd.read_csv(avg_graphs_meta['edgedf']['path'] + '.csv')
node_df = pd.read_csv(avg_graphs_meta['nodedf']['path'] + '.csv')



cols = list(node_df.columns)
[cols.remove(x) for x in ['node', 'condition']]


for metric in cols:
    
    # Ensure seaborn styling
    sns.set(style="whitegrid")
    # Get list of unique conditions (excluding baseline)
    baseline = reference
    all_conditions = node_df['condition'].unique()
    compare_conditions = [cond for cond in all_conditions]#[cond for cond in all_conditions if cond != baseline]
    
    # Prepare figure
    n = len(compare_conditions)
    ncols = 2
    nrows = int(np.ceil(n*1./ncols))
    
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(6*ncols, 4 * nrows), sharex=False)
    
    if n == 1:
        axes = [axes]  # make iterable if only one subplot
    
    # Plot each condition vs. baseline
    #fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(6 * ncols, 4 * nrows), sharex=False)
    #if n > 1:
    axes = axes.flatten()  # Flatten to 1D for easy indexing
    
    for i, cond in enumerate(compare_conditions):
        ax = axes[i]
        # Subset the dataframe for baseline and current condition
        df_baseline = node_df[node_df['condition'] == baseline]
        df_current = node_df[node_df['condition'] == cond]
    
        # Merge the two on 'node' so they're aligned
        merged = pd.merge(df_baseline, df_current, on='node', suffixes=('_baseline', f'_{cond}'))
    
        # Melt for seaborn
        plot_df = pd.melt(
            merged,
            id_vars='node',
            value_vars=[metric + '_baseline', f'{metric}_{cond}'],
            var_name='source',
            value_name= metric
        )
    
        # Clean up labels for clarity
        plot_df['source'] = plot_df['source'].map({
            metric + '_baseline': baseline,
            f'{metric}_{cond}': cond
        })
    
        # Plot
        sns.barplot(data=plot_df, x='node', y= metric, hue='source', ax=ax)
        ax.set_title(f'{cond} vs {baseline}')
        ax.set_ylabel(metric)
        #ax.set_xlabel('Node')
        ax.tick_params(axis='x', rotation=90)
        ax.legend()#title='Condition')
    
    # If there are unused subplots, hide them
    for j in range(n, len(axes)):
        fig.delaxes(axes[j])  # or axes[j].axis('off')
    
    
    plt.tight_layout()
    #plt.show()
    
    save_dir = my.check_if_dir_exists(str(result_dir / 'averaged_graphs') +'/figures/')
    fig.savefig(save_dir + 'nodes_metric=' + metric + '_againstref=' + reference +  '.png')
