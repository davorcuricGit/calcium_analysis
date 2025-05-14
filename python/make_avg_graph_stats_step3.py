#calculate average graph properties like mean degree, mean betweeness and so on.
#requires step2
from init_analysis import *

#load meta
with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

#get nodes df
node_df = pd.read_csv(avg_graphs_meta['nodedf']['path'] + '.csv')

#get the graphs
graphs = dict()
for key in avg_graphs_meta['avg_graph'].keys():
    G = nx.read_gml(avg_graphs_meta['avg_graph'][key]['path'] + '.' + avg_graphs_meta['avg_graph'][key]['format'])
    graphs[key] = G

cols = list(node_df.columns)
[cols.remove(x) for x in ['node', 'condition', 'Unnamed: 0']]


key = list(graphs.keys())
df = pd.DataFrame({'keys' : key})
metric_list = list()

for key in graphs.keys():
    G = graphs[key]
    #print(key,nx.is_strongly_connected(G))
       
    # Get the edge weights for each edge in the graph
    weights = list(nx.get_edge_attributes(G, 'weight').values())
    X = weights 
    tag = 'weight'
    metric_list.append(tag)
    df = my.get_stats(X, tag, key, df)
    
    
    #get pre-calculated node stats
    for c in cols:
        X = [G.nodes[node][c] for node in list(G.nodes())]
        df = my.get_stats(X, c, key, df)
        metric_list.append(c)
    

    #get gini coefficient
    X = my.gini(weights)
    tag = 'gini'
    metric_list.append(tag)
    df = my.get_stats(X, tag, key, df)

    #get average shortest path
    if nx.is_strongly_connected(G):
        X = nx.average_shortest_path_length(G, weight = lambda x,y,z: 1/z['weight'])
        tag = 'ASPL'
        metric_list.append(tag)
        df = my.get_stats(X, tag, key, df)
    else:
        g_strong = G.copy()
        X = 0
        tag = 'ASPL'
        metric_list.append(tag)
        df = my.get_stats(X, tag, key, df)
        
metric_list = list(set(metric_list))        
df.head()




#save the node_df file
save_name = 'avg_graph_stats_df'
save_dir = str(result_dir / 'averaged_graphs')
avg_graphs_meta[save_name] = {'path': str(save_dir) + '/' + save_name,
                                    'save_dir': str(save_dir),
                                    'save_name': save_name,
                                    'format' : 'csv',
                                    'num_cols' : df.shape[1],
                                    'num_rows' : df.shape[0],
                                    'metric_list': metric_list
                                   }

df.to_csv(avg_graphs_meta[save_name]['path'] + '.csv')

with open(str(result_dir / 'averaged_graphs') + '/' + 'avg_graphs_meta.pkl', 'wb') as f:
    pickle.dump(avg_graphs_meta, f) 
