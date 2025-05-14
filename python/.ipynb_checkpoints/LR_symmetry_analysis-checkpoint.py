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
    dmeta = subject_json[av_json['needs']]['act_map_nodes']
    nodes = my.get_needed_derivative(dmeta, subject_json, project)
    
    # Load edges
    dmeta = subject_json[av_json['needs']]['act_map_edges']
    edges = my.get_needed_derivative(dmeta, subject_json, project)
    
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


#######################################################3
# Check left-right asymmetry

#check left-right asymettry of weights
edge_properties_df = pd.DataFrame(columns = ['condition', 'source', 'target', 'left', 'right'])
zero_factor = 10**-7

for key in np.unique(df['cond']):
    GL = avg_graphs[key + '/left']
    GR = avg_graphs[key + '/right']

    for source in GL.nodes():
        for target in GL.nodes():
            if GL.has_edge(source, target):
                Lweight = GL[source][target]['weight']
            else:
                Lweight = zero_factor
            if GR.has_edge(source, target):
                Rweight = GR[source][target]['weight']
            else:
                Rweight = zero_factor
            row = pd.DataFrame({'condition': key, 'source': source, 'target': target, 'left': Lweight, 'right': Rweight}, index = [0])
            edge_properties_df = pd.concat([edge_properties_df, row], ignore_index = True)#.append(, ignore_index=True)

edge_properties_df['avg_lr'] = (edge_properties_df['left'] + edge_properties_df['right']) / 2
edge_properties_df = edge_properties_df.sort_values(['source','target'])

asymm_df = pd.DataFrame(columns = ['condition', 'left_zeros', 'right_zeros', 'asymmetry', 'total weights'])
ncols = int(np.ceil(np.sqrt(len(df['keys']))))
nrows = int(np.ceil(np.sqrt(len(df['keys']))))

for i,cond in enumerate(np.unique(df['cond'])):
    #ax = plt.subplot(nrows,ncols,i+1)

    lr_weights = edge_properties_df[edge_properties_df['condition'] == cond]
    #lr_weights.plot(ax= ax, x = 'left', y = 'right', kind = 'scatter', alpha = 0.5, title= cond, loglog = True, figsize = (20,20))
    #plot_reference_line()
  
    l_asymm = (lr_weights[(lr_weights['left'] == zero_factor) & (lr_weights['right'] > zero_factor)])
    r_asymm = (lr_weights[(lr_weights['left'] > zero_factor) & (lr_weights['right'] == zero_factor)])
    asymm =  (len(r_asymm)+1)/ (len(l_asymm)+1)
    row = pd.DataFrame({'condition': cond, 'left_zeros': len(l_asymm), 'right_zeros':len(r_asymm), 'asymmetry': asymm, 'total weights':len(lr_weights)}, index = [0])
    asymm_df = pd.concat([asymm_df, row], ignore_index = True)

asymm_df['l_fraction'] = asymm_df['left_zeros']/asymm_df['total weights']
asymm_df['r_fraction'] = asymm_df['right_zeros']/asymm_df['total weights']

ax = asymm_df.plot(x = 'condition', y = ['l_fraction', 'r_fraction'], kind = 'bar')

save_dir = my.check_if_dir_exists(result_dir / 'averaged_graphs' / 'figures')
ax.figure.savefig(save_dir +'/' + 'asymmetry_analysis.png')

###################################################################
#save graphs as GLM 

