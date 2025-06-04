#!/bin/bash

set -e  # stop on error

echo "Running make_individual_GML_graphs_step0.py"
python3 make_individual_GML_graphs_step0.py

echo "Running make_individual_FCGML_graphs_step0.py"
python3 make_individual_FCGML_graphs_step0.py

echo "Running make_individual_LRavgd_graphs_step1.py"
python3 make_individual_LRavgd_graphs_step1.py

echo "Running make_individual_graphstats_step2.py"
python3 make_individual_graphstats_step2.py

# echo "Running make_avg_graph_stats_step3.py"
# python3 make_avg_graph_stats_step3.py


# echo "making figures"
# python3 LR_symmetry_analysis.py

# python3 fig_compare_weights_against_ref.py

# python3 fig_compare_metrics_as_bars.py

# python3 fig_weights_cdf_KStest.py

# python3 fig_avg_graph_metrics_barplots.py

# python3 fig_avg_graph_nodes_weighted_by_metric.py
