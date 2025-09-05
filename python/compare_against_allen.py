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

need_step = map_type + '_event_graph'
graphs = dict()

for i, subject_file in enumerate(subject_jsons):
    #try:
    with open(subject_file, 'r') as f:
        subject_json = json.load(f)

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']

    # Load nodes
    try :
        #get the event based network
        en_name = subject_json[need_step][tag + 'thresh=' + str(thresh)]['left_right_avgd']

        #get the functional connectome
        try:
            fc_name = subject_json['len_control_FC']['gml']
        except:
            fc_name = subject_json['FC']['FC_len_control']['gml']
            
            
            
    except Exception as e:
        print(e)
        #print('need_step likely does not exist, i = ' + str(i))
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



#######################################################
#######################################################main analysis
#######################################################


#ref = project['reference_condition']
if computer == 'neumann':
    condition_list = ['Baseline', 'PostShock', 'Post1Hr', 'Post24Hr']
else:
    condition_list = list(df['condition'].unique())

    
for i,cond in enumerate(condition_list):
    
    save_dir = project['calcium_analysis_root'] 
    save_dir += '/' + 'event_based_networks/python/results/' + computer + '/individual/FCcomparison/' + cond + '/'
    save_dir = my.check_if_dir_exists(save_dir)
    
    
    #################################get condition we want to subselect on
    
    df_sub = df[df['condition'].str.contains(cond)]# == ref]
    # Filter out rows containing the substring in 'col1'
    exclusion_list = ['Homecage Ctrl_Post1Hr', 'Homecage Ctrl_PostHomecage','Homecage Ctrl_Post24Hr', 'ChronicKet_Post1Hr',
                      'ChronicKet_PostShock','ChronicKet_24Hours','Nov.Env.Ctrl_Post1Hr', 'Nov.Env.Ctrl_PostNov.Env.','Nov.Env.Ctrl_Post24Hr']

    for ex in exclusion_list:
        df_sub = df_sub[~df_sub['condition'].str.contains(ex)]
        #df_sub = df_sub[~df_sub['condition'].str.contains('ChronicKet_PostShock')]
    
    
    
    #################################gather edge information into a dataframe
    edge_comparison_df = get_edge_comparison_df(df_sub)
    
    
    
    #################################get the allen institute network
    f_loc = project['calcium_analysis_root']
    f_name = f_loc + '/codes/auxfiles/' + '41586_2019_1716_MOESM5_ESM.xlsx'
    
    cortex= list(G.nodes())
    cortex = [x.replace('1', '') for x in cortex]
    cortex.sort()
    
    adj_mat = get_structure_adj(f_name, cortex)
    
    
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
    Allen_diag = my.nanzscore(np.diag(adj_mat))
      
    #set diagonal elements to nan (there has to be a smarter way of doing this -_-)
    np.fill_diagonal(A_EN, 0.123456)
    A_EN[A_EN == 0.123456] = np.nan
    
    np.fill_diagonal(adj_mat, 0.123456)
    adj_mat[adj_mat == 0.123456] = np.nan

    
    #get log-symmetric matricies
    fc0 = np.log10(A_EN)
    fc0 += np.transpose(fc0)

    fc = np.log10(adj_mat)
    fc += np.transpose(fc)


    
    ################################# plot adjacency

    bg_colour = [0.2,0,0.3]
    f, axes = plt.subplots(3, 2, figsize = (6,8), sharex = False, sharey = False)
    
    #bring together the different adjacency matricies to plot them
    M = [A_EN, fc0, A_FC, adj_mat, fc]
    subplotpos = [[0,0], [1,0], [2,0], [0,1], [1,1]]
    
    for i,m in enumerate(subplotpos):
        ax = axes[m[0],m[1]]
        plt.sca(ax)
        plt.imshow(M[i])
        ax.set_facecolor(bg_colour)
        plt.yticks(ticks=np.arange(len(cortex)), labels=cortex);
        plt.xticks(ticks=np.arange(len(cortex)), labels=cortex, rotation=-90);
    

    ax = axes[2,1]
    plt.sca(ax)
    plt.plot(cortex,EN_diag)
    plt.plot(cortex,Allen_diag)
    
    nanidx = (~np.isnan(EN_diag)) & (~np.isnan(Allen_diag))
    rho = stats.pearsonr(EN_diag[nanidx], Allen_diag[nanidx]).statistic
    plt.xticks(ticks=np.arange(len(cortex)), labels=cortex, rotation=-90);
    plt.title(str(rho))
        
    #plt.delaxes(axes[2,1])
    plt.tight_layout()
    #plt.show()
    
    plt.savefig(save_dir + 'adjmats_comparison' + tag + '.png')

    calcium_export = pd.DataFrame(A_EN)
    calcium_export.to_csv(save_dir + 'events_based_adjmat' + tag + '.csv')
    
    
    
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

    df_to_export = pd.DataFrame({'pair': labels, 'correlation': rlist, 'pvalue': pvlist, 'error_low': lower_errors, 'error_high': upper_errors})
    df_to_export.to_csv(save_dir + 'correlation_table' + tag + '.csv')
    
    plt.figure(figsize = (3,3))
    x = range(len(labels))
    plt.errorbar(labels, rlist,yerr=asymmetric_error, fmt=  '.', markersize = 20)
    #ax = plt.gca()
    ax.set_ylabel('Correlation')
    ax.tick_params(left=False)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    plt.tight_layout()
    plt.savefig(save_dir + 'adjmats_correlations' + tag + '.png')



    #plt.show()
    
