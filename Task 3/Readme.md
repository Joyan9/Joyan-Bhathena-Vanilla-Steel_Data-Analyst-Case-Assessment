# Recommendation Pipeline - Installation & Usage Guide

This guide will help you set up and run the buyer recommendations pipeline for the Vanilla Steel data analysis project.

## Prerequisites

- Python 3.7 or higher
- Git (for cloning the repository)

## Installation Steps

1. **Clone the GitHub repository & Set Working Directory**

   ```bash
   gh repo clone Joyan9/Joyan-Bhathena-Vanilla-Steel_Data-Analyst-Case-Assessment
   ```

   ```bash
   cd "Joyan-Bhathena-Vanilla-Steel_Data-Analyst-Case-Assessment/Task 3"
   ```

1. **Set up a Python virtual environment (recommended)**

   ```bash
   # Create a virtual environment
   python -m venv venv
   
   # Activate the virtual environment
   # On Windows:
   venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```

2. **Install required dependencies**

   ```bash
   pip install -r requirements.txt
   ```

## Running the Recommendation Pipeline

1. **Ensure Working Directory**
   
   Make sure you set the working directory before running the script.
   
   `cd "Joyan-Bhathena-Vanilla-Steel_Data-Analyst-Case-Assessment/Task 3"`

2. **Run the recommendation pipeline**

   ```bash
   python run_recommendations_pipeline.py
   ```

## Understanding the Code Structure

The recommendation pipeline consists of two main Python files:

- **load_resources.py**: Handles data loading and resource management
- **run_recommendations_pipeline.py**: The main script that executes the recommendation logic

The pipeline uses DuckDB to run SQL queries that have been optimized for performance and compatibility with DuckDB's syntax.

## Troubleshooting Common Issues

If you encounter errors related to:

- **Missing tables or views**: Ensure your data files are in the correct locations and formats
- **DuckDB syntax errors**: The SQL has been updated to work with DuckDB, but if you make modifications, ensure they follow DuckDB syntax
- **Import errors**: Verify that all required packages are installed

## Customization

To modify the recommendation logic, you can edit the SQL queries in the Python files. The buyer recommendation algorithm considers:

- Material grade matching
- Surface finish requirements
- Thickness and width dimensions
- Weight limitations
- Quantity requirements
