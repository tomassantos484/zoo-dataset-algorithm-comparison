# Algorithm Comparison & Pattern Mining on the Zoo Dataset 🐯

## Overview
This project applies multiple classification algorithms and association rule mining techniques to the classic Zoo dataset to evaluate model performance and uncover meaningful biological patterns among animal traits.

The analysis was completed as a graduate-level assignment for CUS 610 (Data Science Concepts and Methods), emphasizing method comparison, evaluation rigor, and interpretability, rather than purely predictive optimization. The project demonstrates how different supervised learning algorithms perform on a multiclass, imbalanced dataset, as well as how Apriori can reveal co-occurring attribute patterns.

---

## Objectives
The primary objectives of this project were to:

- Compare multiple **classification algorithms** on the same dataset
- Evaluate model performance using accuracy, confidence intervals, and Cohen’s Kappa
- Apply **Apriori association rule mining** to discover frequent co-occurring animal traits
- Interpret discovered patterns in the context of real-world biological characteristics
- Demonstrate a fully reproducible **data mining workflow in R**

---

## Dataset
- **Source:** [Zoo dataset (UCI Machine Learning Repository/Kaggle](https://www.kaggle.com/datasets/uciml/zoo-animal-classification)
- **Records:** 101 animals
- **Attributes:** Binary biological traits (e.g., hair, feathers, milk, aquatic)
- **Target Variable:** `type` (7 animal classes)

---

## Preprocessing & Filtering
To ensure valid modeling and fair comparisons:

- Removed unique identifier (`animal`)
- Converted `"true"` / `"false"` character values into logical attributes
- Converted `type` into a categorical factor
- Verified the dataset contained **no missing or invalid values**
- Applied **stratified sampling** to preserve class proportions during train/test split

After cleaning, the dataset retained all 99 observations across 17 meaningful features.

---

## Classification Methods

### Models Evaluated
- **Decision Tree** (`rpart`)
- **Naive Bayes** (`e1071`)
- **Random Forest** (`randomForest`, 200 trees)

### Evaluation Metrics
- Accuracy
- 95% Confidence Interval
- Cohen’s Kappa
- Confusion Matrices

### Results Summary
| Model         | Accuracy |  Kappa  |
|---------------|----------|---------|
| Decision Tree | ~92.6%   | ~0.897% |
| Naive Bayes   | ~88.9%   | ~0.851% |
| Random Forest | *~96.3%* |*~0.948%*|

**Random Forest achieved the highest accuracy and strongest agreement**, demonstrating superior performance on this dataset compared to simpler models.

---

## Association Rule Mining

### Data Transformation for Apriori
To prepare the dataset for association rule mining:
- Removed `type` (unsupervised analysis)
- Removed numeric attribute `legs`
- Converted binary attributes:
  - `TRUE` → attribute name (e.g., `"fins"`)
  - `FALSE` → `NA`
- Converted the dataset into transaction format using `arules`

Each animal was treated as a transaction, and each biological trait as an item.

---

### Apriori Configuration
Multiple Apriori runs were performed with different support and confidence thresholds:

- **Run 1:** support = 30%, confidence = 60%
- **Run 2:** support = 50%, confidence = 80%
- **Run 3 (highlighted):** support = 10%, confidence = 70%

> Warnings regarding maximum rule length reflect default `arules` behavior and do not affect the validity of the extracted rules.

---

## Key Findings
- High-lift rules strongly characterized **fish-like animals**, driven by traits such as `aquatic`, `fins`, and absence of lungs.
- Certain biological traits consistently co-occurred, reinforcing known zoological classifications.
- Lower support thresholds surfaced more **distinctive and interpretable patterns**, while higher thresholds produced broader, more generic rules.
- Association rules aligned closely with real-world animal biology, validating Apriori as an effective exploratory tool.

## Repository Structure

  ```text
  zoo-dataset-algorithm-comparison/
  │
  ├── data/
  │   ├── raw/                        # Original Zoo dataset (zoo.csv)
  │   └── processed/                  # Cleaned datasets, model metrics, Apriori outputs
  │
  ├── environment/
  │   └── packages.R                  # Required R packages for reproducibility
  │
  ├── src/
  │   └── project_script.R            # End-to-end analysis script (classification + Apriori)
  │
  ├── report/
  │   └── algorithm_comparison_report.pdf  # Final written assignment submission
  │
  ├── visuals/                        # Plots, confusion matrices, and model visuals
  │
  ├── .gitignore
  ├── LICENSE
  └── README.md
  ```

## Reproducibility
To reproduce the analysis:

1. Clone the repository
   ```bash
     git clone https://github.com/tomassantos484/zoo-dataset-algorithm-comparison.git

2. Open the project in RStudio or desired IDE
3. Install and load required packages
   ```bash
     source("environment/packages.R")
   
4. Run the analysis
    ```bash
    source("src/project_script.R")

---

## Tools & Technologies
- R
- RStudio
- caret
- rpart
- rpart.plot
- e1071
- randomForest
- arules
- tidyselect

## Author
[**Tomas Santos Yciano — Connect with me on LinkedIn!**](https://www.linkedin.com/in/tjsy/)

## License
This project is released under the MIT License.
The dataset is provided by Kaggle and subject to its original licensing terms.
