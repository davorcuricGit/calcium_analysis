#plot precalculated metrics in node_df on the graph itself.
#requires avg_graph_stats (step3)
from init_analysis import *
import seaborn as sns
from scipy.stats import ks_2samp
from scipy import stats

with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

node_df = pd.read_csv(avg_graphs_meta['nodedf']['path'] + '.csv')
cols = list(node_df.columns)
[cols.remove(x) for x in ['node', 'condition', 'Unnamed: 0']]

graphs = dict()
for key in avg_graphs_meta['avg_graph'].keys():
    G = nx.read_gml(avg_graphs_meta['avg_graph'][key]['path'] + '.' + avg_graphs_meta['avg_graph'][key]['format'])
    graphs[key] = G

n = len(graphs.keys())
ncols = len(cols)
nrows = n#int(np.ceil(n / ncols))

plotting_fac = 200;

count = 0
for i,key in enumerate(graphs.keys()):

    G = graphs[key]


    nrows = int(np.ceil(3./4*np.sqrt(len(cols))))
    ncols = int(np.ceil(4./3*np.sqrt(len(cols))))
                
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(3 * ncols, 3 * nrows), sharex=False);
    axes = axes.flatten() ; # Flatten to 1D for easy indexing
    count = 0
    
    for c in cols:
        node_size = np.array([G.nodes[node][c] for node in list(G.nodes())])
        node_size = plotting_fac*node_size/max(node_size)
        my.draw_weighted_graph(G, node_size = node_size, title = key + ' ' + c, figsize = (1,1), ax = axes[count]);
        count += 1

    plt.tight_layout();

    #save the figure
    save_dir = my.check_if_dir_exists(result_dir / 'averaged_graphs' / key )
    save_name = 'avg_graphs_nodes_weighted_metric'        
    fig.savefig(str(save_dir) + '/' + save_name + '.png')
