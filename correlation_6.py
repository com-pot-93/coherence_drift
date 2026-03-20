#!/usr/bin/env python3
import argparse
import os

# 1️⃣ Create argument parser
parser = argparse.ArgumentParser(description="Process LLM name and debug flag")

## 2️⃣ Required positional argument: llm name
#parser.add_argument("llm", type=str, help="Name of the LLM")

# 3️⃣ Optional flag -d (default False)
parser.add_argument("-d", "--debug", action="store_true",
                    help="Enable debug mode (optional)")

# 4️⃣ Parse arguments
args = parser.parse_args()

# 5️⃣ Access arguments
#llm_name = args.llm
det_mode = args.debug

# 6️⃣ Print to verify
#print(f"LLM name: {llm_name}")
print(f"Debug mode: {det_mode}")


current_dir = os.getcwd()
folder_path = os.path.join(current_dir, "model_info")
print(folder_path)
selected_files = []



for file_name in os.listdir(folder_path):
    full_path = os.path.join(folder_path, file_name)  # full path
    if os.path.isfile(full_path):  # only files
        if det_mode and not file_name.startswith("det"):
            continue
        if not det_mode and file_name.startswith("det"):
            continue
        selected_files.append(full_path)

import pandas as pd

overview = []

# Suppose 'files' is a list of file paths (from previous code)
for file in selected_files:
    print(f"Processing {file}")

    # Read Excel file
    xlsx = pd.read_excel(file, engine="openpyxl", header=None)

    # Iterate over rows
    for _, row in xlsx.iterrows():
        # Convert row to list
        values = row.tolist()
        # Append column 14 (index 14) as target
        overview.append([values[13],values[14]])


# Optional: convert overview to pandas DataFrame
overview_df = pd.DataFrame(overview)
print("Overview shape:", overview_df.shape)

import pandas as pd
from scipy.stats import pearsonr

# Assume overview_df is already created
df = overview_df

# Get column names for convenience
cols = df.columns

# Initialize empty DataFrames for correlation and p-values
corr_matrix = pd.DataFrame(index=cols, columns=cols, dtype=float)
pval_matrix = pd.DataFrame(index=cols, columns=cols, dtype=float)
# Compute pairwise correlation and p-value
for col1 in cols:
    for col2 in cols:
        r, p = pearsonr(df[col1], df[col2])
        corr_matrix.loc[col1, col2] = r
        pval_matrix.loc[col1, col2] = p
pval_matrix_normal = pval_matrix.applymap(lambda x: float(f"{x:.6f}"))
# Display results
print("===== Correlation Matrix =====")
print(corr_matrix)

print("\n===== P-Value Matrix =====")
print(pval_matrix)


