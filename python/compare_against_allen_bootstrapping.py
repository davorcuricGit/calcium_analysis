from init_analysis import *


#compare event-based networks against allen instutie data


import math
from scipy import stats
from scipy.special import softmax
import seaborn as sns


def create_graph(adj_matrix):
    G = nx.MultiDiGraph()
    G.add_nodes_from(CORTEX)
    for index, i in enumerate(CORTEX):
        for jndex, j in enumerate(CORTEX):
            if i == j:
                continue
            weight = adj_matrix[index, jndex]
            G.add_edge(i, j, weight=weight)
    return G

def get_structure_adj(f_name, nodes):

    df_structure = pd.read_excel(f_name, sheet_name='all CC connection strengths')
    
    df_structure= df_structure[(df_structure['hemisphere']=='ipsi')]# & (df_structure['Mouse Line']=='Rbp4-Cre_KL100')]#'C57BL/6J / Emx1')]
    
    #scortex = ['VISp-1', 'VISl', 'VISal', 'VISpm', 'VISam', 'VISrl']
    
    CC_connectivity = np.zeros((len(nodes),len(nodes)))
    for sndex, source in enumerate(nodes):
        for tndex, target in enumerate(nodes):
            #if sndex == tndex:
            #    CC_connectivity[sndex, tndex] = np.nan
            #    continue
            CC_connectivity[sndex, tndex] = df_structure[(df_structure['Exp Source']==source) & (df_structure['Target']==target)]['NPV (online)'].mean()
    adj_mat = CC_connectivity
    
    return adj_mat

def adj_correlation(X,Y):
    #calculate the correlation coefficient between two matricies X and Y
    
    mask1 = np.isfinite(X)
    mask2 = np.isfinite(Y)
    
    mask = mask1 & mask2
    
    X = X[mask]
    Y = Y[mask]
    
    rho = stats.pearsonr(X, Y)
    r = rho.statistic
    pv = rho.pvalue
    CI = rho.confidence_interval
    return r,pv,CI



def get_edge_comparison_df(df_sub):
    #compile dataframe from edges in networkx graphs for both event-based and functionalnetworks
    edge_comparison_df = pd.DataFrame(columns = ['idx', 'src', 'trg', 'FCw', 'ENw'])
    for i,row in df_sub.iterrows():
        G = row['EN']
        F = row['FC']
    
        common_nodes = set(G.nodes).intersection(set(F.nodes))
    
        area = nx.get_node_attributes(G,'area')
        activation = nx.get_node_attributes(G, 'activation')
        
        for m, u in enumerate(common_nodes):
            for n,v in enumerate(common_nodes):
                #if u == v:
                #    continue
                    
                if G.has_edge(u,v) and F.has_edge(u,v):
                    we = (G[u][v]['weight'])/area[u]**0/activation[u]**1
                    wf = (F[u][v]['weight'])
                elif not G.has_edge(u,v) and F.has_edge(u,v):
                    we = (0)
                    wf = (F[u][v]['weight'])
                elif G.has_edge(u,v) and not F.has_edge(u,v):
                    we = (G[u][v]['weight'])/area[u]**0/activation[u]**1
                    wf = (0)
                else:
                    we = 0
                    wf = 0
    
                #gather source-target infomration for functional network and event-based-network 
                row = {'idx': i, 'src': u, 'trg': v, 'FCw': wf, 'ENw': we}
                row = pd.DataFrame(row, index=[0])
    
                edge_comparison_df = pd.concat([edge_comparison_df, row], ignore_index=True)
    
                
    edge_comparison_df['ENw_norm'] = edge_comparison_df['ENw']/edge_comparison_df['ENw'].max() + 0*10**-5
    edge_comparison_df['FCw'] += 0*10**-5
    
    edge_comparison_df['ENw_sftmx'] = softmax(np.array(list(edge_comparison_df['ENw'].values)))
    edge_comparison_df['FCw_sftmx'] = softmax(np.array(list(edge_comparison_df['FCw'].values)))

    return edge_comparison_df




#################################gather graphs into a dataframe
map_type = 'act_map'
need_step = map_type + '_event_graph'
graphs = dict()
thresh = 1
for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

    # Load nodes
    try :
        #get the event based network
        print(need_step)
        print(subject_json.keys())
        en_name = subject_json[need_step]['thresh=' + str(thresh)]['left_right_avgd']

        #get the functional connectome
        fc_name = subject_json['len_control_FC']['gml']
    except Exception as e:
        
        print(f"An error occurred: {e}")
        print('need_step likely does not exist, i = ' + str(i))
        stop
        continue
        
    # Extract label
    condition = subject_json['init']['condition']
    if 'cohort' in condition:
        condition = re.sub(r'_cohort\d+', '', condition)
    if 'First arm' in condition:
        condition = re.sub('First arm', '', condition)
    if 'Second arm' in condition:
        condition = re.sub('Second arm', '', condition)
    
    G = nx.read_gml(path_name + '/' + en_name + '.gml')
    F = nx.read_gml(path_name + '/' + fc_name)
    
    graphs[i] = {'condition': condition, 'FC': F, 'EN': G}

df = pd.DataFrame(graphs).T

print(df.head())

#######################################################
#######################################################main analysis
#######################################################


#ref = project['reference_condition']
if computer == 'neumann':
    #condition_list = #['PostShock', 'Post1Hr', 'Post24Hr']#'Baseline']#, 
    condition_list = list(df['condition'].unique())
else:
    condition_list = list(df['condition'].unique())



    
for i,cond in enumerate(condition_list):
    
    save_dir = project['calcium_analysis_root'] 
    save_dir += '/' + 'event_based_networks/python/results/' + computer + '/individual/FCcomparison/' + cond + '/'
    save_dir = my.check_if_dir_exists(save_dir)
    
    
    #################################get condition we want to subselect on
    
    df_sub = df[df['condition'].str.contains(cond)]# == ref]
    print(cond)
    if len(df_sub) == 1:
            print('skipping condition: ' + cond)
            continue
    # Filter out rows containing the substring in 'col1'
    if computer == 'neumann':
#        exclusion_list = ['Homecage Ctrl_Post1Hr', 'Homecage Ctrl_PostHomecage','Homecage Ctrl_Post24Hr', 'ChronicKet_Post1Hr',
#                          'ChronicKet_PostShock','ChronicKet_24Hours','Nov.Env.Ctrl_Post1Hr', 'Nov.Env.Ctrl_PostNov.Env.','Nov.Env.Ctrl_Post24Hr']
        exclusion_list = ['ChronicKet_Post1Hr', 'ChronicKet_PostShock','ChronicKet_24Hours']
    else:
        exclusion_list = []

    for ex in exclusion_list:
        df_sub = df_sub[~df_sub['condition'].str.contains(ex)]
        #df_sub = df_sub[~df_sub['condition'].str.contains('ChronicKet_PostShock')]


   #################################get the allen institute network
    f_loc = project['calcium_analysis_root']
    f_name = f_loc + '/codes/auxfiles/' + '41586_2019_1716_MOESM5_ESM.xlsx'
    
    cortex= list(G.nodes())
    cortex = [x.replace('1', '') for x in cortex]
    cortex.sort()
    
    adj_mat = get_structure_adj(f_name, cortex)
    Allen_diag = my.nanzscore(np.diag(adj_mat))
    np.fill_diagonal(adj_mat, 0.123456)
    adj_mat[adj_mat == 0.123456] = np.nan

    dfs = []
    
        
    for trial in range(10):
        #bootstrap here
        
        df_sub_samp =  df_sub.sample(frac=0.5, replace=True)
        
        #################################gather edge information into a dataframe
        edge_comparison_df = get_edge_comparison_df(df_sub_samp)
        
        
        #################################get adjacency for event based and fc networks
        
        vishier= list(G.nodes())
        vishier.sort()
        L = len(vishier)
        ed_df= edge_comparison_df.copy()
        
        A_EN = np.zeros([L,L])
        A_FC = np.zeros([L,L])
        
        #make the event-networks and function-connectome adjacency 
        for i,u in enumerate(vishier):
            for j,v in enumerate(vishier):
                row = ed_df[(ed_df['src'] == u) & (ed_df['trg'] == v)]
                A_EN[i,j] = row['ENw_norm'].mean()
                A_FC[i,j] = row['FCw'].mean()
    
    
        #################################get diagonal elements
    
        EN_diag = my.nanzscore(np.diag(A_EN))
          
        #set diagonal elements to nan (there has to be a smarter way of doing this -_-)
        np.fill_diagonal(A_EN, 0.123456)
        A_EN[A_EN == 0.123456] = np.nan
            
        #get log-symmetric matricies
        fc0 = np.log10(A_EN)
        fc0 += np.transpose(fc0)
    
        fc = np.log10(adj_mat)
        fc += np.transpose(fc)
    
          
        #################################get correlations between pairs of adjanceny matriccie
        pairs = [[A_EN, adj_mat], [fc0, fc], [fc0, A_FC], [fc, A_FC]]
        labels = ['S-Sa', 'logS-logSa', 'logS-FC', 'logSa-FC']
        
        rlist = list()
        CI_list = list()
        pvlist = list()
        
        for i,pair in enumerate(pairs):
            r,pv,CI = adj_correlation(pair[0], pair[1])
            c = CI(confidence_level=0.9)
            rlist.append(r)
            pvlist.append(pv)
            CI_list.append([c.low, c.high])
        
        
        # Convert CI_list to asymmetric error
        lower_errors = [r - ci[0] for r, ci in zip(rlist, CI_list)]
        upper_errors = [ci[1] - r for r, ci in zip(rlist, CI_list)]
        asymmetric_error = [lower_errors, upper_errors]
    
        dfs.append(pd.DataFrame({'trial': trial, 'pair': labels, 'correlation': rlist, 'pvalue': pvlist, 'error_low': lower_errors, 'error_high': upper_errors}))

    df_to_export = pd.concat(dfs, ignore_index = True)
    df_to_export.to_csv(save_dir + 'correlation_table_bootstrap.csv')
        
    
