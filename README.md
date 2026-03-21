# coherence_drift

## Repository Overview

This folder provides code, prompts, generated artifacts, and evaluation reports.

---

## Dependencies

Code for template-based model-to-text transformation and process-model transformation into traversal sequences (TS transformation):

👉 https://github.com/etm/cpee-transformation

> ⚠️ **Important Setup Note**
The repository must be cloned into a separate folder at the same directory level as this one:
>
> ```
> - transformation
> - coherence\_drift
> ```
>
> Otherwise, relative import paths must be adjusted accordingly.

Required gems: `daru`, `caxlsx`, `roo`, `gruff`, `optparse`, `csv`, `damerau-levenshtein`, `rag\_embeddings`, `hungarian\_algorithm`, `hungarian\_algorithm\_c`, `curb`, `json`, `net-http-post-multipart`, `uri`, `stringio`, `xml-smart`.

---

## Directory Structure

- **`process\_models/`**
  Contains all initial process models.

- **`iterations/`**
  Contains all generated models and corresponding process descriptions for each pipeline.

- **`prompts/`**
  Contains prompts used for transformation functions.

- **`reports/`**
  Contains Excel sheets with final averaged data used for tables in the paper.

- **`evaluation/`**
  Contains detailed (non-averaged) SCD values between initial and final models.

- **`model\_info/`**
  Contains detailed (non-averaged) element counts for initial and final process models.

- **`multi/`**
  Contains detailed (non-averaged) iteration numbers where the first drift occurrence appears.

- **`all\_sim/`**
  Contains detailed (non-averaged) SCD values for each process model in the pipeline.

- **`all\_svg/`**
  Contains visualizations of `all\_sim` for each dataset and pipeline.



## Code and Scripts Overview

scripts for pipeline execution, evaluation, similarity computation, and visualization.

---

### Pipeline and Data Generation

- **`pipeline.rb`** – Executes pipelines and generates data (`./iterations`).
  Use `scripts\_to\_generate.sh` to process all datasets and pipelines.

---

### Evaluation

- **`evaluation.rb`** – Calculates SCD for all pipelines and LLMs (`./evaluation`).
- **`evaluate\_model\_info.rb`** – Computes element counts for initial and final models (`./model\_info`).
- **`evaluate\_multi\_sequences.rb`** – Computes first drift occurrence (`./multi`).
- **`evaluate\_all\_sim.rb`** – Computes similarity of each generated model with the initial (`./all\_sim`).

Use the corresponding scripts (`scripts\_to\_run\_full.sh`, `scripts\_to\_info.sh`, `scripts\_to\_multi.sh`, `scripts\_to\_all.sh`) for all datasets and pipelines.

---

### Traversal Sequence Similarity (TS Sim)

- **`trace\_sim\_threshold.rb`** – Calculates sequence similarity between two process models.
- **`trace\_sim\_multi.rb`** – Identifies the start of drift (`true/false`).
> Works only with TS transformation.

---

### Visualization & Support

- **`svg\_linechart.rb`** – Creates linecharts for drift behavior (`./all\_svg`).
- **`example.rb`** – Generates example data for Figure 2.
- **`all\_functions.rb`** – Contains supporting functions.
- Other scripts (e.g., `correlation\_6-8.py`, `report\_eval\_sheet1-14.rb`) generate reports (`./reports`) from calculated or generated data.




