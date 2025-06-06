from init_analysis import *
import seaborn as sns
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler


def build_node_dataframe(subject_nodedata, condition_lookup):
    all_data = []

    for subject_id, nodedata in subject_nodedata.items():
        condition = condition_lookup.get(subject_id, "unknown")
        for brain_region, props in nodedata.items():
            row = props.copy()
            row['Brain Region'] = brain_region
            row['subject'] = subject_id
            row['condition'] = condition
            all_data.append(row)

    return pd.DataFrame(all_data)


#collect node stats into dataframe
map_type = 'act_map'
need_step = map_type + '_event_graph'
graphs_list = dict()

subject_nodedata = dict()
condition_lookup = dict()
# subject_nodedata = {
#     "sub-01": nodedata1,
#     "sub-02": nodedata2,
#     # ...
# }

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

    # Extract label
    condition = subject_json['init']['condition']
    if 'cohort' in condition:
        condition = re.sub(r'_cohort\d+', '', condition)
    if ' AL' in condition: #remove awake like conditions in anesthetics analysis
        continue

    path_name = subject_json['init']['project_root'] + subject_json['init']['derivative_path']
    
    G = nx.read_gml(path_name + '/' + file_name + '.gml')

    subject_nodedata[subject_json['init']['uniqueid']] = dict(G.nodes(data = True))
    condition_lookup[subject_json['init']['uniqueid']] = condition
    

node_df = build_node_dataframe(subject_nodedata, condition_lookup)
node_df['normalized_selfloop'] = node_df['selfloops']/node_df['area']
node_df = node_df.drop(columns = ['pos', 'area', 'subject'])




#%calculate feature importance
# Encode 'condition' to numerical
top_features = dict()
for region in list(node_df['Brain Region'].unique()):
    try:
        scaler = StandardScaler()
        df = node_df[node_df['Brain Region'] == region].copy()
        
        le = LabelEncoder()
        df['condition_encoded'] = le.fit_transform(df['condition'])

        

        # One-hot encode 'Brain Region' if you treat it as a categorical predictor
        #df_encoded = pd.get_dummies(df, columns=['Brain Region'])
        
        # Choose features to include
        features = [col for col in df.columns if col not in ['subject', 'condition', 'condition_encoded', 'Brain Region']]
        X = df[features].copy()
        
        #normalize the features
        
        X.iloc[:,0::] = scaler.fit_transform(X.iloc[:,0::].to_numpy())
        
        y = df['condition_encoded']
        
        # Train/test split
        X_train, X_test, y_train, y_test = train_test_split(X, y, stratify=y, random_state=42)
        
        # Train random forest
        clf = RandomForestClassifier(n_estimators=100, random_state=42)
        clf.fit(X_train, y_train)
        
        # Feature importance
        importances = pd.Series(clf.feature_importances_, index=X.columns)
        top_features[region] = dict(importances.sort_values(ascending=False).head(20))
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        



# Convert nested dict to DataFrame
df_scores = pd.DataFrame(top_features).T  # transpose so rows = regions, columns = metrics

# Optional: sort rows/columns if needed
df_scores = df_scores.sort_index(axis=0)  # sort brain regions
df_scores = df_scores.sort_index(axis=1)  # sort metrics



plt.figure(figsize=(12, 8))
sns.heatmap(df_scores, cmap='viridis', annot=False, cbar_kws={'label': 'Importance Score'})
plt.title('Feature Importance by Brain Region and Metric')
plt.xlabel('Metric')
plt.ylabel('Brain Region')
plt.tight_layout()
save_dir = my.check_if_dir_exists(str(result_dir / 'individual') +'/figures/')
plt.savefig(save_dir + 'FeatureImportance.png')
        
    

