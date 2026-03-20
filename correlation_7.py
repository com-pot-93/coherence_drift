#!/usr/bin/env python3
import argparse
import os
import pandas as pd
from scipy.stats import pearsonr

parser = argparse.ArgumentParser(description="Process LLM name and deterministic flag")
parser.add_argument("-d", "--deterministic", action="store_true", help="Enable deterministic mode (optional)")
args = parser.parse_args()
det_mode = args.deterministic
#print(f"Debug mode: {det_mode}")

current_dir = os.getcwd()
folder_path = os.path.join(current_dir, "model_info")
selected_files = []
for file_name in os.listdir(folder_path):
    full_path = os.path.join(folder_path, file_name)  # full path
    if os.path.isfile(full_path):  # only files
        if det_mode and not file_name.startswith("det"):
            continue
        if not det_mode and file_name.startswith("det"):
            continue
        selected_files.append(full_path)

overview = []
for file in selected_files:
    print(f"Processing {file}")
    xlsx = pd.read_excel(file, engine="openpyxl", header=None)
    for _, row in xlsx.iterrows():
        values = row.tolist()
        temp = []
        for i in range(6):
            diff = abs(values[i + 1] - values[i + 7])
            temp.append(diff)
        temp.append(1-values[14])
        overview.append(temp)

overview_df = pd.DataFrame(overview)
df = overview_df
cols = df.columns
corr_matrix = pd.DataFrame(index=cols, columns=cols, dtype=float)
pval_matrix = pd.DataFrame(index=cols, columns=cols, dtype=float)

for col1 in cols:
    for col2 in cols:
        r, p = pearsonr(df[col1], df[col2])
        corr_matrix.loc[col1, col2] = r
        pval_matrix.loc[col1, col2] = p

#pval_matrix_normal = pval_matrix.applymap(lambda x: float(f"{x:.6f}"))
print("===== Correlation Matrix =====")
print(corr_matrix[6])
print("\n===== P-Value Matrix =====")
print(pval_matrix[6])


