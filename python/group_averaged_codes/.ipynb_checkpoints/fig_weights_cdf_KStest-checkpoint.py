#requires avg_graph_stats (step3)
from init_analysis import *
import seaborn as sns
from scipy.stats import ks_2samp
from scipy import stats

with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

graphs = dict()
for key in avg_graphs_meta['avg_graph'].keys():
    G = nx.read_gml(avg_graphs_meta['avg_graph'][key]['path'] + '.' + avg_graphs_meta['avg_graph'][key]['format'])
    graphs[key] = G



def plot_ks_distance_matrix(weights):
    keys = list(weights.keys())
    n = len(keys)
    
    # Initialize matrix to store KS distances (D-statistic)
    ks_distances = np.zeros((n, n))
    
    for i in range(n):
        for j in range(n):
            if i <= j:  # Compute upper triangle and diagonal
                d_stat, _ = ks_2samp(weights[keys[i]], weights[keys[j]])
                ks_distances[i, j] = d_stat
                ks_distances[j, i] = d_stat  # Symmetric matrix
    
    # Create heatmap
    plt.figure(figsize=(8, 6))
    snsplot = sns.heatmap(ks_distances, xticklabels=keys, yticklabels=keys,
                annot=True, fmt=".2f", cmap="viridis", cbar_kws={'label': 'KS Distance'})
    plt.title("Pairwise Kolmogorov-Smirnov Distances")
    plt.xlabel("Key")
    plt.ylabel("Key")
    plt.tight_layout()
    fig = snsplot.get_figure()
    return fig
    


# plot weight distribution for each graph
plt.figure(figsize=(6,6))
colorcount = 0
lw = .5
dat = dict()
for i,key in enumerate(graphs.keys()):
    # Load the graph from the dictionary using its key
    G = graphs[key]
    weights = nx.get_edge_attributes(G, 'weight')

    dat[key] = list(weights.values())
    res = stats.ecdf(dat[key])

    #if the colours start to repeat then up the linewidth
    if colorcount > 9:
        lw += .5
        colorcount = 0
        
    fig = plt.plot(res.cdf.quantiles, 1-res.cdf.probabilities, label = key, lw = lw)
    colorcount += 1


plt.legend()
plt.xscale('log')
#plt.yscale('log')
plt.xlabel('weight');
plt.ylabel('cdf');

fig = plt.gcf()
save_dir = my.check_if_dir_exists(str(result_dir / 'averaged_graphs') +'/figures/')
fig.savefig(save_dir + 'weights_cdf' + '.png')

fig = plot_ks_distance_matrix(dat)
save_dir = my.check_if_dir_exists(str(result_dir / 'averaged_graphs') +'/figures/')
fig.savefig(save_dir + 'pairwise_KS_distance_matrix' + '.png')