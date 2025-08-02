from init_analysis import *

#######################################
#take FC saved as .csv and save it as a .gml graph


def average_hemisphere_graphs(G_left, G_right):
    # 1. Find common nodes
    common_nodes = set(G_left.nodes).intersection(set(G_right.nodes))

    # 2. Create averaged graph
    G_avg = nx.Graph()

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

#load allen atlas
allen_df = pd.read_csv('/home/dcuric/Documents/calciumAnalysis/codes/auxfiles/allen_subnetworks.csv')
regions = list(allen_df['labels'].values)
# Step 1: Create a mapping from label to index
label_to_index = dict(zip(allen_df['labels'], allen_df['roi']))

label_to_index = {x.replace('left', 'L').replace('right', 'R'): label_to_index[x] for x in label_to_index.keys()}
regions = [x.replace('left', 'L').replace('right', 'R') for x in regions]

#load fcc
# Loop over subjects
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']
    
   
    try:
        fname = subject_json['len_control_FC']['name']
        if subject_json['len_control_FC']['derivative_extension'] not in fname:
            fname += subject_json['len_control_FC']['derivative_extension']
            
        fc = pd.read_csv(path_name + fname, sep=',', header=None)
    except Exception as e1:

        #sometimes the json structure is different so this ngihtmare of a nested try tries to accomodate.
        #probably a better way to do this....
        try:
            fname = subject_json['FC']['FC_len_control']['name']
            if subject_json['FC']['FC_len_control']['derivative_extension'] not in fname:
                fname += subject_json['FC']['FC_len_control']['derivative_extension']
            
            fc = pd.read_csv(path_name + fname, sep=',', header=None)
        except Exception as e2:
            print(e1)
            print(e2)
            #print('fc does not exist, i = ' + str(i))
            #print('path:' + path_name)
            #print(subject_json['FC'])
            print('')
            continue
        
    
    fc = fc.values
    
    G = nx.Graph()
    G.add_nodes_from(regions)

    edges_to_remove = []

    #mapping = dict()
    #for node in G.nodes():
        #mapping[node] = node.replace('left', 'L').replace('right', 'R')
    #G = nx.relabel_nodes(G, mapping)

    
    # Step 2: Loop over node pairs (upper triangle only, since fc is symmetric)
    nodes = list(G.nodes)
    for i, u in enumerate(nodes):
        for j in range(i + 1, len(nodes)):
            v = nodes[j]

            #if the nodes belong to different hemispheres don't connect them. 
            if u[-1] != v[-1]:
                continue
            
            if u in label_to_index and v in label_to_index:
                idx_u = label_to_index[u]-1
                idx_v = label_to_index[v]-1
                
                weight = fc[idx_u, idx_v]
                if not np.isnan(weight):
                    G.add_edge(u, v, weight=weight)
            else:
                print(f"Skipping pair ({u}, {v}): one or both nodes not found in allen_regions")

    LRnodes = {'L':list(), 'R': list()}
    for node in G.nodes():
        LRnodes[node[-1]].append(node)

    GL = G.subgraph(LRnodes['L'])
    GR = G.subgraph(LRnodes['R'])

    GL = nx.relabel_nodes(GL, {node: node[0:-1].strip() for node in GL.nodes()})
    GR = nx.relabel_nodes(GR, {node: node[0:-1].strip() for node in GR.nodes()})

    G = average_hemisphere_graphs(GL, GR)

    try:
        subject_json['len_control_FC']['gml'] = 'FC_len_control.gml'
        nx.write_gml(G, path_name + '/' +  subject_json['len_control_FC']['gml'])
    except:
        try:
            subject_json['FC']['FC_len_control']['gml'] = 'FC_len_control.gml'
            nx.write_gml(G, path_name + '/' +  subject_json['FC']['FC_len_control']['gml'])
        except:
            print('something went wrong I dont know how you got here lol')
    
    

    with open(subject_file, 'w') as f:
        json.dump(subject_json, f)

    

    #FOR TOMORROW: average weights into one component
    #for k,row in allen_df.iterrows():
