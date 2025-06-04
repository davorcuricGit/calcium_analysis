from init_analysis import *

#######################################
#make per-condition average graph
with open(str(result_dir / 'averaged_graphs/') + '/avg_graphs_meta.pkl', 'rb') as f:
    avg_graphs_meta = pickle.load(f)    

load_name = 'LR_avg_graph'
avg_graphs = dict()
for key in avg_graphs_meta[load_name].keys():
    G = nx.read_gml(avg_graphs_meta[load_name][key]['path'] + '.' + avg_graphs_meta[load_name][key]['format'])
    avg_graphs[key] = G



#average the LR hemispheres into one
graphs = dict()
for key in avg_graphs.keys():
    G = avg_graphs[key]
    LRnodes = {'L':list(), 'R': list()}
    for node in G.nodes():
        LRnodes[node[-1]].append(node)

    GL = G.subgraph(LRnodes['L'])
    GR = G.subgraph(LRnodes['R'])

    GL = nx.relabel_nodes(GL, {node: node[0:-1].strip() for node in GL.nodes()})
    GR = nx.relabel_nodes(GR, {node: node[0:-1].strip() for node in GR.nodes()})

    G = my.average_hemisphere_graphs(GL, GR)
    graphs[key] = G

#make sure all the nodes are the same
inter = set.intersection(*[set(G.nodes()) for G in graphs.values()])
for key in graphs.keys():
    graphs[key] = nx.subgraph(graphs[key], inter)


#save the graphs as GML files
save_name = 'avg_graph'
avg_graphs_meta[save_name] = dict()
for key in graphs.keys():
    G = graphs[key]
    #save the averaged graphs
    save_dir = result_dir / 'averaged_graphs' / key 

    avg_graphs_meta[save_name][key] = {'path': str(save_dir) + '/' + save_name,
                                        'save_dir': str(save_dir),
                                        'save_name': save_name,
                                        'num_recs_for_avg': avg_graphs_meta['LR_avg_graph'][key]['num_recs_for_avg'],
                                        'format' : 'gml',
                                        'num_nodes' : len(G.nodes()),
                                        'num_edges' : len(G.edges()),
                                        'directed' : nx.is_directed(G),
                                        'weighted' : nx.is_weighted(G),
                                        'connected' : nx.is_strongly_connected(G)
                                       }

    #save the graph as gephi file
    nx.write_gml(G, avg_graphs_meta[save_name][key]['path'] + '.' + avg_graphs_meta[save_name][key]['format'])
    
    
with open(str(result_dir / 'averaged_graphs') + '/' + 'avg_graphs_meta.pkl', 'wb') as f:
    pickle.dump(avg_graphs_meta, f) 