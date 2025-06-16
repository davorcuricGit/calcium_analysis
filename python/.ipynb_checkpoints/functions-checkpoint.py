import os
import platform
import pandas as pd
import warnings
import numpy as np
import scipy.io
import warnings
import networkx as nx
from collections import defaultdict
import math
import random
from scipy import stats
import seaborn as sns
import matplotlib.pyplot as plt
from pathlib import Path
import json



def init_analysis(calcium_dir):
    ## initialization stuff
    # Base directory
    
    
    # Get current computer alias
    computer = get_computer_alias(calcium_dir / 'computers.csv')
    
    # Load general analysis configuration
    with open(calcium_dir / 'project_jsons' / 'sourcesink_networks.json', 'r') as f:
        av_json = json.load(f)
    
    # Load the list of projects for this computer
    project_list_path = calcium_dir / 'project_lists' / f'{computer}_project_lists.txt'
    project_lists = pd.read_csv(project_list_path, header=None)
    project_path = project_lists.iloc[0, 0]
    with open(project_path, 'r') as f:
        project = json.load(f)
    
    reference = project['reference_condition']
    
    project_root = Path(project['project_root']) / project['project_name']
    metadata_path = project_root / project['structure']['metadata']
    # Find all per-subject JSONs recursively
    subject_jsons = list(metadata_path.rglob('*.json'))

    info = {'calcium_dir': calcium_dir, 'computer': computer, 'project': project, 'subject_jsons': subject_jsons, 'av_json': av_json, 'reference': reference}

    return info

def check_if_dir_exists(path):
    if not os.path.exists(path):
        Path(path).mkdir(parents = True, exist_ok = True)
    return str(path)
    

def get_computer_alias(computersfile):
    """
    Load computer aliases from CSV and return the alias for the current computer.
    """
    # Load computer aliases from CSV
    data = pd.read_csv(computersfile)  # Assumes columns: RealName, AliasName

    # Get this computer's actual name from environment variable
    real_name = os.environ.get('COMPUTERNAME') or os.environ.get('HOSTNAME')
    
    if not real_name:
        real_name = platform.node()  # platform fallback
    real_name = real_name.strip()

    # Match and retrieve alias (case-insensitive match)
    matches = data[data['RealName'].str.lower() == real_name.lower()]
    
    if not matches.empty:
        alias = matches['AliasName'].iloc[0]
    else:
        warnings.warn(f'Computer name "{real_name}" not found in computers CSV.')
        alias = real_name  # fallback to real name
    
    return alias


def get_needed_derivative(dmeta, subject_json, project):
    derivative_name = dmeta['name']
    derivative_extension = dmeta['derivative_extension']
    file_name = derivative_name + derivative_extension
    format_ = dmeta['format']

    #floc = os.path.join(project['project_root'], project['project_name'], project['structure']['derivatives'], subject_json['init']['raw_path'], file_name)
    floc = os.path.join(project['project_root'],
                        project['project_name'], 
                        project['structure']['derivatives'])
    floc += subject_json['init']['raw_path'] + '/' + file_name
    
    
    
    return new_load_derivative(floc, dmeta)


def new_load_derivative(floc, dmeta):
    derivative = None

    if not os.path.isfile(floc):
        warnings.warn(f"File does not exist: {floc}")
        dmeta['success'] = 0
        return None

    try:
        if dmeta['derivative_extension'] == '.mat':
            S = scipy.io.loadmat(floc, squeeze_me=True, struct_as_record=False)
            if 'derivative' in S:
                derivative = S['derivative']
            else:
                # If there's only one variable, use that
                keys = [k for k in S.keys() if not k.startswith('__')]
                if keys:
                    derivative = S[keys[0]]
                else:
                    raise ValueError("No usable variables found in .mat file")

        elif dmeta['derivative_extension'] == '.csv':
            if dmeta['format'] in ('table', 'struct2table'):
                derivative = pd.read_csv(floc)
            else:
                try:
                    mat = np.loadtxt(floc, delimiter=',')
                    if dmeta['format'] == 'flattened3D':
                        X = int(np.max(mat[:, 0]))
                        Y = int(np.max(mat[:, 1]))
                        Z = int(np.max(mat[:, 2]))
                        reconstructed = np.zeros((X, Y, Z))
                        for row in mat:
                            i, j, k, val = map(int, row[:3]) + [row[3]]
                            reconstructed[i-1, j-1, k-1] = val  # MATLAB is 1-based
                        derivative = reconstructed
                    else:
                        derivative = mat
                except Exception as e:
                    warnings.warn(f"Failed to load CSV as table or matrix: {e}")
                    return None
        else:
            warnings.warn(f"Unsupported file type: {dmeta['derivative_extension']}")
            return None

    except Exception as e:
        warnings.warn(f"Loading failed: {e}")
        dmeta['success'] = 0
        return None

    return derivative




def plot_reference_line(slope = 1):
    """
    Plots a y=x reference line across the entire domain of the current plot.
    The limits of the line are automatically taken from the current plot's axis.
    """
    # Get the current axis limits
    x_min, x_max = plt.xlim()
    y_min, y_max = plt.ylim()
    
    # Determine the range for the line
    line_min = min(x_min, y_min)
    line_max = max(x_max, y_max)
    
    # Plot the y=x line
    plt.plot([line_min, line_max], [slope*line_min, slope*line_max], 'k--', label='y=x')
    plt.legend()

# edges_list: list of M dataframes, each with ['source', 'target', 'weight']
# Example: edges_list = [df0, df1, df2, ...] for M recordings
def combine_edges(edges_list):
    combined_df = None
    for i, df in enumerate(edges_list):
        df = df.copy()
        df = df[['source', 'target', 'weight']].dropna()
        df.rename(columns={'weight': f'weight_{i}'}, inplace=True)
        if combined_df is None:
            combined_df = df
        else:
            combined_df = pd.merge(combined_df, df, on=['source', 'target'], how='outer')
    
    return combined_df


def combine_nodes(nodes_list):
    activation_frames = []
    
    for i, df in enumerate(nodes_list):
        df = df.copy()
        df.rename(columns={'activations': f'activations_{i}'}, inplace=True)
        activation_frames.append(df[['names', f'activations_{i}']])
    
    # Merge activations across all recordings
    from functools import reduce
    
    merged_activations = reduce(
        lambda left, right: pd.merge(left, right, on='names', how='outer'),
        activation_frames
    )
    
    # Compute average posx, posy, and area
    # (Assuming nodes_list all have same 'name' order and content)
    positions = pd.concat([df[['names', 'posx', 'posy', 'area']] for df in nodes_list])
    avg_positions = (
        positions.groupby('names', as_index=False)
        .mean()
        .rename(columns={'posx': 'avg_posx', 'posy': 'avg_posy', 'area': 'avg_area'})
    )
    
    # Merge averages and activations
    combined_nodes_df = pd.merge(avg_positions, merged_activations, on='names')
    return combined_nodes_df
    # Optional: if you want a cleaner structure, fill NaNs with 0s (or keep NaNs if that matters)
    # combined_df = combined_df.fillna(0)

# Start with identifying metadata columns
def group_nodes_by_label(combined_nodes_df, label):

    # Group column indices by label
    label_to_indices = defaultdict(list)
    for i, label_val in enumerate(label):
        label_to_indices[label_val].append(i)
    
    node_metadata = combined_nodes_df[['names', 'avg_posx', 'avg_posy', 'avg_area']]
    
    # Group activations
    node_condition_dfs = []
    for condition, indices in label_to_indices.items():
        
        cols = [f'activations_{i}' for i in indices]
        # Compute row-wise mean
        mean_activation = combined_nodes_df[cols].mean(axis=1)
        condition_df = node_metadata.copy()
        condition_df[f'mean_activation_{condition}'] = mean_activation
        node_condition_dfs.append(condition_df[['names', f'mean_activation_{condition}']])
    
    # Merge all condition-specific activations
    grouped_nodes_df = reduce(lambda left, right: pd.merge(left, right, on='names'), node_condition_dfs)
    
    # Add metadata back
    grouped_nodes_df = pd.merge(node_metadata, grouped_nodes_df, on='names')

    return grouped_nodes_df

def groupe_edges_by_label(combined_edges_df, label):
    # Group column indices by label
    label_to_indices = defaultdict(list)
    for i, label_val in enumerate(label):
        label_to_indices[label_val].append(i)
    
    # Metadata
    edge_metadata = combined_edges_df[['source', 'target']]
    
    # Group weights
    edge_condition_dfs = []
    for condition, indices in label_to_indices.items():
        cols = [f'weight_{i}' for i in indices if f'weight_{i}' in combined_edges_df.columns]
        mean_weight = combined_edges_df[cols].mean(axis=1)
        condition_df = edge_metadata.copy()
        condition_df[f'mean_weight_{condition}'] = mean_weight
        edge_condition_dfs.append(condition_df[['source', 'target', f'mean_weight_{condition}']])
    
    # Merge all condition-specific weights
    grouped_edges_df = reduce(
        lambda left, right: pd.merge(left, right, on=['source', 'target'], how='outer'),
        edge_condition_dfs
    )
    return grouped_edges_df


def get_stats(X, tag, key, df):
    mu = np.median(X)
    df.loc[df['keys'] == key, tag + '_75th'] = np.percentile(X, 75) - 1*mu
    df.loc[df['keys'] == key, tag +'_25th'] = 1*mu - np.percentile(X, 25)
    df.loc[df['keys'] == key, tag +'_median'] = mu
    df.loc[df['keys'] == key, tag +'_mean'] = np.mean(X)
    df.loc[df['keys'] == key, tag +'_std'] = np.std(X)
    df.loc[df['keys'] == key, tag +'_min'] = np.min(X)
    df.loc[df['keys'] == key, tag +'_max'] = np.max(X)
    return df


def average_graphs_by_condition(graphs, labels):
    condition_groups = defaultdict(list)
    for G in graphs:
        condition = G.graph['condition']
        condition_groups[condition].append(G)

    averaged_graphs = {}

    for condition, group in condition_groups.items():
 
        # Create new graph
        G_avg = nx.DiGraph()
        G_avg.graph['condition'] = condition

        # --- Nodes ---
        all_nodes = set().union(*[G.nodes for G in group])
        for node in all_nodes:
            attrs = defaultdict(list)
            for G in group:
                if node in G:
                    for attr in ['activation', 'area']:
                        if attr in G.nodes[node]:
                            attrs[attr].append(G.nodes[node][attr])
                    if 'pos' in G.nodes[node]:
                        attrs['posx'].append(G.nodes[node]['pos'][0])
                        attrs['posy'].append(G.nodes[node]['pos'][1])
            
            if attrs:
                avg_activation = np.mean(attrs['activation']) if attrs['activation'] else 0
                avg_area = np.mean(attrs['area']) if attrs['area'] else 0
                #avg_posx = np.mean(attrs['posx']) if attrs['posx'] else 0
                #avg_posy = np.mean(attrs['posy']) if attrs['posy'] else 0
                if attrs['posx'] and attrs['posy']:
                    avg_pos = (np.mean(attrs['posx']), np.mean(attrs['posy']))
                else:
                    avg_pos = (0, 0)  # or np.nan, or skip the node entirely
                G_avg.add_node(node, activation=avg_activation, area=avg_area, pos=avg_pos)#(avg_posx, avg_posy))

        # --- Edges ---
        edge_weights = defaultdict(list)
        for G in group:
            for u, v, data in G.edges(data=True):
                edge_weights[(u, v)].append(data['weight'])

        for (u, v), weights in edge_weights.items():

            #pad the weights to make sure that if one recording is missing an edge it still contributes to the average.
            weights = np.pad(weights, (0, len(group) - len(weights)))
            avg_weight = np.mean(weights)
            
            G_avg.add_edge(u, v, weight=avg_weight)

        G_Avg = remove_nan_position_nodes(G_avg)
        averaged_graphs[condition] = G_avg

    return averaged_graphs

def remove_nan_position_nodes(G):
    nodes_to_remove = []
    for node, data in G.nodes(data=True):
        x, y = data.get('pos')#, data.get('posy')
    
        if x is None or y is None or math.isnan(x) or math.isnan(y):
            nodes_to_remove.append(node)
    
    G.remove_nodes_from(nodes_to_remove)
    return G

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
        

#put node properties into df
def calculate_node_proprties(G, key):
    #node_df = pd.DataFrame(columns = ['condition', 'node', 'indegree' , 'outdegree', 'between', 'clustering', 'activation'])
    
#for key in graphs.keys():
#    G = graphs[key]
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

    #graphs[key] = G
    
    #node_df = pd.concat([node_df, stats_row]);
    return stats_row, G#node_df, G#graphs
    


def draw_weighted_graph(G, title=None, node_size=100, scale=5, figsize = (3,3), show_fig = True, ax = None):
    # Get node positions from attributes
    pos = {
        node: [data['pos'][0], -data['pos'][1]]
        for node, data in G.nodes(data=True)
        if 'pos' in data
    }

    # Get edge weights
    weights = [G[u][v]['weight'] for u, v in G.edges]
    max_weight = max(weights) if weights else 1
    widths = [scale * w / max_weight for w in weights]  # Scale for visibility

    # Draw the graph
    fig = plt.figure(figsize=figsize)
    #plt.subplot(nrows, ncols, subplotidx)
    nx.draw_networkx_nodes(G, pos, node_size=node_size, node_color='skyblue', edgecolors='k', ax = ax)
    nx.draw_networkx_edges(G, pos, width=widths, edge_color='gray', arrows=True, connectionstyle="arc3,rad=0.1", ax = ax)
    nx.draw_networkx_labels(G, pos, font_size=8, ax = ax)

    if title:
        if ax is not None:
            ax.set_title(title)
        else:
            plt.title(title)

    if ax is None:
        plt.axis('off')
        plt.tight_layout()
        if show_fig:
            plt.show()
    
    return fig

def gini(x, w=None):
    # The rest of the code requires numpy arrays.
    x = np.asarray(x)
    if w is not None:
        w = np.asarray(w)
        sorted_indices = np.argsort(x)
        sorted_x = x[sorted_indices]
        sorted_w = w[sorted_indices]
        # Force float dtype to avoid overflows
        cumw = np.cumsum(sorted_w, dtype=float)
        cumxw = np.cumsum(sorted_x * sorted_w, dtype=float)
        return (np.sum(cumxw[1:] * cumw[:-1] - cumxw[:-1] * cumw[1:]) / 
                (cumxw[-1] * cumw[-1]))
    else:
        sorted_x = np.sort(x)
        n = len(x)
        cumx = np.cumsum(sorted_x, dtype=float)
        # The above formula, with all weights equal to 1 simplifies to:
        return (n + 1 - 2 * np.sum(cumx) / cumx[-1]) / n


def compare_metrics_as_bars(node_df, metric, reference):
    # Ensure seaborn styling
    sns.set(style="whitegrid")
    # Get list of unique conditions (excluding baseline)
    baseline = reference
    all_conditions = node_df['condition'].unique()
    compare_conditions = [cond for cond in all_conditions if cond != baseline]
    
    # Prepare figure
    n = len(compare_conditions)
    ncols = 2
    nrows = int(np.ceil(n*1./ncols))
    
    #fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(4*ncols, 4 * nrows), sharex=False)
    
    if n == 1:
        axes = [axes]  # make iterable if only one subplot
    
    # Plot each condition vs. baseline
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(6 * ncols, 4 * nrows), sharex=False)
    axes = axes.flatten()  # Flatten to 1D for easy indexing
    
    for i, cond in enumerate(compare_conditions):
        ax = axes[i]
        # Subset the dataframe for baseline and current condition
        df_baseline = node_df[node_df['condition'] == baseline]
        df_current = node_df[node_df['condition'] == cond]
    
        # Merge the two on 'node' so they're aligned
        merged = pd.merge(df_baseline, df_current, on='node', suffixes=('_baseline', f'_{cond}'))
    
        # Melt for seaborn
        plot_df = pd.melt(
            merged,
            id_vars='node',
            value_vars=[metric + '_baseline', f'{metric}_{cond}'],
            var_name='source',
            value_name= metric
        )
    
        # Clean up labels for clarity
        plot_df['source'] = plot_df['source'].map({
            metric + '_baseline': baseline,
            f'{metric}_{cond}': cond
        })
    
        # Plot
        sns.barplot(data=plot_df, x='node', y= metric, hue='source', ax=ax)
        ax.set_title(f'{cond} vs {baseline}')
        ax.set_ylabel(metric)
        #ax.set_xlabel('Node')
        ax.tick_params(axis='x', rotation=90)
        ax.legend()#title='Condition')
    
    # If there are unused subplots, hide them
    for j in range(n, len(axes)):
        fig.delaxes(axes[j])  # or axes[j].axis('off')
    
    
    plt.tight_layout()
    plt.show()
    
    return fig


def make_graph(nodes_df, edges_df, condition):
        
    G = nx.DiGraph()

    # Add nodes with attributes
    for _, row in nodes_df.iterrows():
        G.add_node(row['names'], pos=(row['posx'], row['posy']), area=row['area'], activation=row['activations'])


    # Build lookup for source activations
    activation_dict = dict(zip(nodes_df['names'], nodes_df['activations']))

    # Add edges with adjusted weights
    for _, row in edges_df.iterrows():
        source = row['source']
        target = row['target']
        raw_weight = row['weight']
        source_activation = activation_dict.get(source, 1)  # Avoid division by zero or missing key
        target_area = G.nodes[target]['area']
        
        # Compute adjusted weight
        if source_activation != 0:
            adjusted_weight = raw_weight / source_activation**0 / target_area**0
        else:
            adjusted_weight = 0  # or np.nan or skip the edge

        G.add_edge(source, target, weight=adjusted_weight, raw_weight=raw_weight)

    
    #remove nodes with very small cortical areas
    nodes_to_remove = list()
    for node in G.nodes():
        if G.nodes[node]['area'] < 50:
            nodes_to_remove.append(node)
    [G.remove_node(node) for node in nodes_to_remove]
            
    # remove nodes with 0,0 location
    nodes_to_remove = list()
    for node in G.nodes():
        if G.nodes[node]['pos'][0] == 0:
            nodes_to_remove.append(node)
    [G.remove_node(node) for node in nodes_to_remove]
            
    
    G.graph['condition'] = condition
    return G


def generate_weight_shuffled_surrogate(G):
    # Copy structure (edges and nodes) but not weights
    G_surr = nx.DiGraph()
    G_surr.add_nodes_from(G.nodes(data=True))  # preserves node attributes

    # Extract current weights from all edges
    edges = list(G.edges())
    weights = [G[u][v]['weight'] for u, v in edges]

    # Shuffle the weights
    random.shuffle(weights)

    # Assign shuffled weights to the same edges
    for (u, v), w in zip(edges, weights):
        G_surr.add_edge(u, v, weight=w)

    return G_surr

def generate_multiple_surrogates(G, n_surrogates, seed=None):
    """
    Generate a list of surrogate graphs with shuffled weights.
    
    Parameters:
        G (nx.DiGraph): Original graph with weighted edges.
        n_surrogates (int): Number of surrogate graphs to generate.
        seed (int or None): Random seed for reproducibility.
    
    Returns:
        List of nx.DiGraph objects.
    """
    if seed is not None:
        random.seed(seed)

    edges = list(G.edges())
    original_weights = [G[u][v]['weight'] for u, v in edges]
    nodes_with_attrs = list(G.nodes(data=True))

    surrogates = []

    for _ in range(n_surrogates):
        weights = original_weights.copy()
        random.shuffle(weights)

        G_surr = nx.DiGraph()
        G_surr.add_nodes_from(nodes_with_attrs)

        for (u, v), w in zip(edges, weights):
            G_surr.add_edge(u, v, weight=w)

        surrogates.append(G_surr)

    return surrogates

def flatten_list(my_list):
    return [x for xs in my_list for x in xs]

def nanzscore(X):
    X = X - np.nanmean(X)
    X = X/np.nanstd(X)
    return X
