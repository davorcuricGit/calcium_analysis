#requires avg_graph_stats (step3)
from init_analysis import *
import seaborn as sns

with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

df = pd.read_csv(avg_graphs_meta['avg_graph_stats_df']['path'] + '.csv')
metric_list = avg_graphs_meta['avg_graph_stats_df']['metric_list']

for metric in metric_list:
    # Create figure and axis
    plt.figure(figsize=(10, 6))
    
    # Make the barplot but disable CI/errorbars
    barplot = sns.barplot(data=df, x='keys', y= metric + '_mean',  errorbar=None, hue = 'keys', palette='pastel')
    
    # Add error bars manually
    # Get the positions of the bars
    x_coords = []
    for bars in barplot.containers:
        for bar in bars:
            x = bar.get_x() + bar.get_width() / 2
            x_coords.append(x)
    x_coords = np.sort(x_coords)
    
    
    # Extract error values
    yerr_lower = df[metric + '_25th'].values
    yerr_upper = df[metric + '_75th'].values
    yerr = [yerr_lower, yerr_upper]
    
    # Add error bars
    plt.errorbar(x_coords, df[metric + '_mean'], yerr=yerr, fmt='none', ecolor='black', capsize=5)
    
    # Final touches
    plt.xlabel('Condition')
    plt.ylabel('Mean ' + metric)
    plt.title('Mean ' + metric + ' with 25th–75th Percentile Ranges')
    plt.xticks(rotation=45)
    plt.tight_layout()
    #plt.show()

    fig = barplot.get_figure()
    save_dir = my.check_if_dir_exists(str(result_dir / 'averaged_graphs') +'/figures/')
    fig.savefig(save_dir + 'avg_graph_metric_barplots=' + metric + '.png')