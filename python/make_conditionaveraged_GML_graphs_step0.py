from init_analysis import *

#######################################
#make per-condition average graph


avg_graphs = dict()
graph_list = list()
label = list()
hemi = list()

df = pd.DataFrame()

# Loop over subjects
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    # Set step parameters
    thresh = 1
    av_json['parameters']['threshold'] = thresh
    av_json['needs'] = f'event_network_thresh_{thresh}'
    av_json['type'] = 'avalanches'
    
    # Load nodes
    try :
        dmeta = subject_json[av_json['needs']]['act_map_nodes']
        nodes = my.get_needed_derivative(dmeta, subject_json, project)
    except:
        print('nodes does not exist, i = ' + str(i))
        continue
        
    
    # Load edges
    try:
        dmeta = subject_json[av_json['needs']]['act_map_edges']
        edges = my.get_needed_derivative(dmeta, subject_json, project)
    except:
        print('edges does not exist, i = ' + str(i))
        continue

    
    # Extract label
    condition = subject_json['init']['condition']
    if 'cohort' in condition:
        condition = re.sub(r'_cohort\d+', '', condition)

    G = my.make_graph(nodes, edges, condition)
    G.remove_edges_from(nx.selfloop_edges(G))

    # Separate nodes into hemispheres
    left_nodes = [n for n in G.nodes if 'left' in n.lower()]
    right_nodes = [n for n in G.nodes if 'right' in n.lower()]
    
    GG = [G.subgraph(left_nodes).copy(), G.subgraph(right_nodes).copy()]
    lr_label = ['left', 'right']
    for i,g in enumerate(GG):
        g = nx.relabel_nodes(g, {node: node.split(' ')[0] for node in g.nodes()})
        g.graph['condition'] = condition + '/' + lr_label[i]
        g.graph['hemisphere'] = lr_label[i]
        graph_list.append(g)
        hemi.append(lr_label[i])
        label.append(condition)

avg_graphs = my.average_graphs_by_condition(graph_list, label)

key = [g.graph['condition'] for g in graph_list]
df = pd.DataFrame({'keys' : key, 'cond': label, 'hemi': hemi})


###################################################################
#save graphs as GML 

#plot both hemispheres of the averaged graphs
save_name = 'LR_avg_graph'
avg_graphs_meta = dict()
avg_graphs_meta[save_name] = dict()
for key in np.unique(df['cond']):
    GL = avg_graphs[key + '/left']
    GL = nx.relabel_nodes(GL, {node: node + ' L' for node in GL.nodes()})

    GR = avg_graphs[key + '/right']
    GR = nx.relabel_nodes(GR, {node: node + ' R' for node in GR.nodes()})

    G = nx.union(GL, GR)
    fig = my.draw_weighted_graph(G, title = key, figsize = (5,5), show_fig = False)
    
    
    
    save_dir = result_dir / 'averaged_graphs' / key 
    if not os.path.exists(save_dir):
        Path(save_dir).mkdir(parents = True, exist_ok = True)
        
    #save the figure
    fig.savefig(str(save_dir) + '/' + save_name + '.png')
    plt.close(fig)
    
    #save the averaged graphs
    avg_graphs_meta[save_name][key] = {'path': str(save_dir) + '/' + save_name,
                                        'save_dir': str(save_dir),
                                        'save_name': save_name,
                                        'num_recs_for_avg': len([x for x in label if x == key]),
                                        'format' : 'gml',
                                        'num_nodes' : len(G.nodes()),
                                        'num_edges' : len(G.edges()),
                                        'directed' : nx.is_directed(G),
                                        'weighted' : nx.is_weighted(G),
                                        'connected' : nx.is_strongly_connected(G)
                                       }
    #save the graph as gephi file
    nx.write_gml(G, avg_graphs_meta[save_name][key]['path'] + '.' + avg_graphs_meta[save_name][key]['format'])
    
    
with open(str(result_dir / 'averaged_graphs') + '/avg_graphs_meta.pkl', 'wb') as f:
    pickle.dump(avg_graphs_meta, f)    
