#requires nodes and edges file (step2)
from init_analysis import *

with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

edge_df = pd.read_csv(avg_graphs_meta['edgedf']['path'] + '.csv')
node_df = pd.read_csv(avg_graphs_meta['nodedf']['path'] + '.csv')

#plot weights against reference
conds = list(avg_graphs_meta['avg_graph'].keys())
ncols = int(np.ceil(3./4*np.sqrt(len(conds))))
nrows = int(np.ceil(4./3*np.sqrt(len(conds))))
count = 1
plt.figure(figsize = (ncols*4,nrows*4))
cond1 = reference 
cond1_weights = edge_df[cond1]



for j,cond2 in enumerate(conds):
    cond2_weights = edge_df[cond2]

    
    plt.subplot(nrows, ncols, count)
    count += 1
    plt.scatter(cond1_weights, cond2_weights, alpha = 0.5)
    my.plot_reference_line()
    my.plot_reference_line(slope = 50)
    my.plot_reference_line(slope = 1./50)
    plt.xscale('log')
    plt.yscale('log')
    #plt.title(cond1 + ' vs ' + cond2)
    plt.xlabel(cond1)
    plt.ylabel(cond2)
    ax = plt.gca()
    ax.get_legend().remove()

save_dir = my.check_if_dir_exists(str(result_dir / 'averaged_graphs') +'/figures/')
plt.savefig(save_dir + 'weights_comparison_reference=' + reference +  '.png')