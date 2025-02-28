# Task 1 Approach Description - Data Cleaning & Preparation

The goal of this task was to clean and merge data from two Excel files (`supplier_data_1.xlsx` and `supplier_data_2.xlsx`) into a single, unified dataset named `inventory_dataset`. I chose to work with Python and Jupyter Notebook in this case as the dataset were as xlsx files and required a lot of data cleaning steps.

## **Approach**
I used the following Python libraries

```python
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import re
```

 - `pandas`: For data manipulation and working with DataFrames.
 - `numpy`: For numerical operations.
 - `matplotlib.pyplot & seaborn`: For data visualization.
 - `re`: Regular Expression Operations - Used it for cleaning incorrect formats

I conducted initial exploration of both datasets using `.head()`, `.info()`, and `.describe()` methods to understand the structure, data types, missing values, and summary statistics. I noticed that both the datasets were quite different and therefore chose to create an inventory dataset that was functional - with only necessary values like: grade, dimensions, weight etc.

And since both datasets were quite varied, I had to work on them independently (one at a time).

### **Data Cleaning and Transformation**

- *Handling Missing Values*- Missing values were handled based on the column. Some columns had missing values imputed with the mean/median/mode. Other columns, where imputation was not suitable, were filled with a placeholder value (e.g., "UNKNOWN") or left as `NaN` for further analysis.
- *Standardizing Column Names*- Column names were standardized to ensure consistency between the two datasets. This involved renaming columns to a common format (e.g., using lowercase with underscores) and resolving naming discrepancies.
- *Data Type Conversion*- Data types were converted where necessary to ensure consistency and facilitate analysis. For example, numeric columns were converted to appropriate numeric types (`int` or `float`), and date columns were converted to datetime objects.
- *Handling inconsistencies*- Removed duplicates and corrected any inconsistencies identified.
- *Supplier Column*- Add a column named `supplier` to identify each company.
- After cleaning and standardizing the data, the two datasets were merged into a single `inventory_dataset` using the `pd.concat()` function. This combined the rows from both datasets into a unified table.
