from init_analysis import *

def average_hemisphere_graphs(G_left, G_right):
    # 1. Find common nodes
    common_nodes = set(G_left.nodes).intersection(set(G_right.nodes))

    # 2. Create averaged graph
    G_avg = nx.DiGraph()

    for node in common_nodes:
        attr_left = G_left.nodes[node]
        attr_right = G_right.nodes[node]

        avg_activation = (attr_left['activation'] + attr_right['activation']) / 2
        avg_area = (attr_left['area'] + attr_right['area']) / 2

        pos_left = attr_left['pos']
        pos_right = attr_right['pos']
        avg_pos = ((pos_left[0] + 0*pos_right[0]) / 1, (pos_left[1] + 0*pos_right[1]) / 1)

        G_avg.add_node(node, activation=avg_activation, area=avg_area, pos=avg_pos)

    # 3. Average edges
    for src in common_nodes:
        for tgt in common_nodes:
            #if src == tgt:
            #    continue

            w_left = G_left[src][tgt]['weight'] if G_left.has_edge(src, tgt) else 0
            w_right = G_right[src][tgt]['weight'] if G_right.has_edge(src, tgt) else 0
            avg_weight = (w_left + w_right) / 2

            if avg_weight > 0:
                G_avg.add_edge(src, tgt, weight=avg_weight)

    return G_avg


#######################################

#make a graph that averages the left and right hemispheres together

map_type = 'act_map'
step_name = map_type + '_event_graph'

need_step = step_name
graphs_list = dict()
thresh = 1

# Loop over subjects
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

        # Load nodes
    try :
        file_name = subject_json[need_step]['thresh=' + str(thresh)]['save_name']
    except:
        print('need_step likely does not exist, i = ' + str(i))
        continue
        
    
    G_OG = nx.read_gml(path_name + '/' + file_name + '.gml')
    
    LRnodes = {'L':list(), 'R': list()}
    for node in G_OG.nodes():
        LRnodes[node[-1]].append(node)

    GL = G_OG.subgraph(LRnodes['L'])
    GR = G_OG.subgraph(LRnodes['R'])

    GL = nx.relabel_nodes(GL, {node: node[0:-1].strip() for node in GL.nodes()})
    GR = nx.relabel_nodes(GR, {node: node[0:-1].strip() for node in GR.nodes()})

    G = average_hemisphere_graphs(GL, GR)

    step_name = map_type + '_LRavgd_graph' + '_thresh=' + str(thresh)
    save_dir = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

    subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd'] = step_name
    nx.write_gml(G, save_dir + '/' + subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd'] + '.gml')
    
    with open(subject_file, 'w') as f:
        json.dump(subject_json, f)
 
