from init_analysis import *

#######################################


def weighted_reciprocity(G):
    nodes = list(G.nodes())

    outdegree = G.out_degree(weight = 'weight')
    outdegree = G.out_degree()
    outdegree = {x[0]:x[1] for x in outdegree}
    
    rec = dict()
    for u in nodes:
        w = list()
        if outdegree[u] == 0:
            rec[u] = 0
        else:
            for v in nodes:
                if u == v:
                    continue
                if not G.has_edge(u,v) and not G.has_edge(v,u):
                    continue
                elif not G.has_edge(u,v) and G.has_edge(v,u):
                    w.append(0)
                elif G.has_edge(u,v) and not G.has_edge(v,u):
                    w.append(0)                
                else:
                    wuv = G[u][v]['weight']
                    wvu = G[v][u]['weight']
                    w.append(min([wuv,wvu])/max([wuv,wvu]))
                            
            rec[u] = sum(w)/outdegree[u]

    return rec
        

def calculate_node_proprties(G, key):
    #takes in graph and calculates various properties
    nodes = G.nodes(data = True)
    
    names = list(G.nodes())
    conds = [key] * len(nodes)
    in_degrees = [x[1] for x in G.in_degree(weight = 'weight')] 
    out_degrees = [x[1] for x in G.out_degree(weight = 'weight')]
    
    between = nx.betweenness_centrality(G, normalized=True, weight = lambda x,y,z: 1/z['weight'])
    between = list(between.values())

    clustering = nx.clustering(G, weight = 'weight')
    clustering = list(clustering.values())

    activation = [n[1]['activation'] for n in nodes]
    area = [n[1]['area'] for n in nodes]

    reciprocity = nx.reciprocity(G, nodes = names)
    reciprocity = list(reciprocity.values())

    w_reciprocity = weighted_reciprocity(G)
    w_reciprocity = list(w_reciprocity.values())
    
    stats_row = pd.DataFrame({'condition': conds, 
                        'node': names, 
                        'indegree': in_degrees, 
                        'outdegree': out_degrees, 
                        'between': between, 
                        'clustering': clustering,
                        'activation': activation,
                        'reciprocity': reciprocity,
                        'w_reciprocity': w_reciprocity})
    
    #put the stats back into the node as attributes
    cols = list(stats_row.columns)
    [cols.remove(x) for x in ['node', 'condition']]
    for _, row in stats_row.iterrows():
        node = row['node']
        if node in G:
            for attr in cols:
                G.nodes[node][attr] = row[attr]

    return stats_row, G#node_df, G#graphs


#calculate graph stats

map_type = 'act_map'
need_step = map_type + '_event_graph'
graphs_list = dict()

# Loop over subjects
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    # Load nodes
    try :
        file_name = subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd']
    except:
        print('need_step likely does not exist, i = ' + str(i))
        continue

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']
    
    G = nx.read_gml(path_name + '/' + file_name + '.gml')

    stats_df,G = calculate_node_proprties(G, i)
    save_dir = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

    nx.write_gml(G, save_dir + '/' + subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd'] + '.gml')

 
