# analysis_setup.py

import importlib
import sys
import csv
import numpy as np
import matplotlib.pyplot as plt
import os
import pandas as pd
import json
import re
from pathlib import Path
from functools import reduce
import networkx as nx
import random
from itertools import combinations  
import math
import pickle

sys.path.insert(0, '/Documents/calciumAnalysis/codes/python/')

import functions as my
importlib.reload(my)

calcium_dir = Path.home() / 'Documents' / 'calciumAnalysis'
info = my.init_analysis(calcium_dir)
computer = info['computer']
project = info['project']
subject_jsons = info['subject_jsons']
av_json = info['av_json']
reference = info['reference']

result_dir = calcium_dir / 'event_based_networks' / 'python' / 'results' / computer
if not os.path.exists(result_dir):
    Path(result_dir).mkdir(parents = True, exist_ok = True)

# Export relevant variables
__all__ = [
    'np', 'plt', 'pd', 'os', 'Path', 're', 'nx', 'random', 'combinations',
    'math', 'pickle', 'my', 'calcium_dir', 'computer', 'project',
    'subject_jsons', 'av_json', 'reference', 'result_dir'
]