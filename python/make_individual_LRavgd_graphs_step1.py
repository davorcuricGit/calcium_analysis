from init_analysis import *

#######################################

#make a graph that averages the left and right hemispheres together

map_type = 'act_map'
step_name = map_type + '_event_graph'

need_step = step_name
graphs_list = dict()

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

    G = my.average_hemisphere_graphs(GL, GR)

    step_name = map_type + '_LRavgd_graph' + '_thresh=' + str(thresh)
    save_dir = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

    subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd'] = step_name
    nx.write_gml(G, save_dir + '/' + subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd'] + '.gml')
    
    with open(subject_file, 'w') as f:
        json.dump(subject_json, f)
 
