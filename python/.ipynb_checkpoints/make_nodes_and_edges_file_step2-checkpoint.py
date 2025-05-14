from init_analysis import *

#######################################
#make csvs for node and edge properties
#requires LRaveraged_GML graphs to have been run

with open(str(result_dir / 'averaged_graphs/') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)  

load_name = 'avg_graph'
graphs = dict()
for key in avg_graphs_meta[load_name].keys():
    G = nx.read_gml(avg_graphs_meta[load_name][key]['path'] + '.' + avg_graphs_meta[load_name][key]['format'])
    graphs[key] = G


#######################################
#calculate properties for the nodes
save_name = 'nodedf'
save_dir = result_dir / 'averaged_graphs/'


metrics = ['indegree' , 'outdegree', 'between', 'clustering', 'activation']
node_df = pd.DataFrame(columns = ['condition', 'node'] + metrics)
for key in graphs.keys():
    G = graphs[key]
    
    stats_df,G = my.calculate_node_proprties(G, key);
    node_df = pd.concat([node_df, stats_df]);
    graphs[key] = G

    #update the graph meta
    avg_graphs_meta['avg_graph'][key]['metrics'] = metrics

    #save the graph
    nx.write_gml(G, avg_graphs_meta['avg_graph'][key]['path'] + '.' + avg_graphs_meta['avg_graph'][key]['format'])



#save the node_df file
avg_graphs_meta[save_name] = {'path': str(save_dir) + '/' + save_name,
                                    'save_dir': str(save_dir),
                                    'save_name': save_name,
                                    'format' : 'csv',
                                    'num_cols' : node_df.shape[1],
                                    'num_rows' : node_df.shape[0]
                                   }

node_df.to_csv(avg_graphs_meta[save_name]['path'] + '.csv')

#################################
#calculate properties for the edges
save_name = 'edgedf'
save_dir = result_dir / 'averaged_graphs/'

conds = list(set(node_df['condition']))
edge_df = pd.DataFrame(columns = ['source_target'] + conds)
zero_factor = 10**-7

nodes = list(set(node_df['node']))

for c in conds:
    G = graphs[c]
    weight = list()
    st = list()
    for source in nodes:
        for target in nodes:
            st.append(source + '_' + target)
            if G.has_edge(source, target):
                weight.append(G[source][target]['weight'])
            else:
                weight.append(zero_factor)
                

    edge_df['source_target'] = st
    edge_df[c] = weight

#save the edge_df file
avg_graphs_meta[save_name] = {'path': str(save_dir) + '/' + save_name,
                                    'save_dir': str(save_dir),
                                    'save_name': save_name,
                                    'format' : 'csv',
                                    'num_cols' : edge_df.shape[1],
                                    'num_rows' : edge_df.shape[0]
                                   }

edge_df.to_csv(avg_graphs_meta[save_name]['path'] + '.csv')

   
with open(str(result_dir / 'averaged_graphs') + '/' + 'avg_graphs_meta.pkl', 'wb') as f:
    pickle.dump(avg_graphs_meta, f) 