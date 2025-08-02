from init_analysis import *


#######################################
#make per-condition average graph


#generate subject graphs
remove_self_loops = False

avg_graphs = dict()
graph_list = dict()
meta = dict()
step_name = map_type + '_event_graph'
meta[step_name] = dict()

label = list()
mouse = list()
uqid = list()
index = list()

df = pd.DataFrame()

# Loop over subjects
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)
    
     # Set step parameters
    thresh = 1
    av_json['parameters']['threshold'] = thresh
    av_json['needs'] = f'event_network_{tag}thresh_{thresh}'
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

    print(dmeta)
    
    
    G = my.make_graph(nodes, edges, condition)
    
    #add the selfloops as a node attribute
    selfloops = list(nx.selfloop_edges(G))
    slweights = {sl[0]: G[sl[0]][sl[1]]['weight'] for sl in selfloops }
    nx.set_node_attributes(G, slweights, 'selfloops')
    
    if remove_self_loops:
        G.remove_edges_from(nx.selfloop_edges(G))

    mapping = dict()
    for node in G.nodes():
        mapping[node] = node.replace('left', 'L').replace('right', 'R') 
    G = nx.relabel_nodes(G, mapping)
    
    graph_list[i] = G

    
    label.append(condition)
    mouse.append(subject_json['init']['mouse'])
    uqid.append(subject_json['init']['uniqueid'])
    index.append(i)

    #save the averaged graphs
    save_dir = subject_json['init']['project_root'] + subject_json['init']['derivative_path']#my.check_if_dir_exists(str(result_dir) + '/' + 'individual_graphs/graphs/' + 'recid=' + str(i) + '_id=' + str(subject_json['init']['uniqueid']))
    subject_json[step_name] = dict()
    subject_json[step_name][tag + 'thresh=' + str(thresh)] = {'path': str(save_dir) + '/' + step_name,
                                        'save_dir': str(save_dir),
                                        'save_name': step_name + tag + '_thresh=' + str(thresh),
                                        'format' : 'gml',
                                        'num_nodes' : len(G.nodes()),
                                        'num_edges' : len(G.edges()),
                                        'directed' : nx.is_directed(G),
                                        'weighted' : nx.is_weighted(G),
                                        'connected' : nx.is_strongly_connected(G),
                                        'map_type' : map_type
                                       }
    #meta[step_name][i] = subject_json[step_name]['thresh=' + str(thresh)] 
    #save the graph as gephi file
    nx.write_gml(G, save_dir + '/' + subject_json[step_name][tag + 'thresh=' + str(thresh)]['save_name'] + '.gml')
    with open(subject_file, 'w') as f:
        json.dump(subject_json, f)

    

# #df = pd.DataFrame({'keys' : index, 'cond': label, 'mouse': mouse, 'uniqueid': uqid})
# with open(meta_file_dir + '/' + meta_file_name + '.pkl', 'wb') as f:
#     pickle.dump(meta, f)  
