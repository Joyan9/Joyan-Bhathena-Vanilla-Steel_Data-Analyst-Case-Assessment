# Task 3 Approach Description - Buyer Preference Matching

The objective of this task was to match supplier materials to buyer preferences and generate a ranked recommendation table.  

### **Approach**  
I selected **DuckDB** as the database solution due to its lightweight nature and ease of local execution.  

The process consisted of:  
1. **Data Extraction & Preparation**  
   - Downloading supplier and buyer preference data from Google Drive (Excel files) using `gdown`.  
   - Converting the files to CSV format for efficient processing.  
   - Loading the cleaned CSV data into a DuckDB database.  

2. **Data Unification**  
   - Standardizing supplier datasets (e.g., harmonizing column names, handling missing values).  
   - Extracting relevant information such as **finish types** from descriptions.  
   - Filtering out unavailable materials based on supplier-specific conditions.  

3. **Buyer Preference Processing**  
   - Standardizing buyer preferences for easier matching.  
   - Translating German finish descriptions into English.  
   - Casting numerical fields (thickness, width, weight) to appropriate data types.  

4. **Recommendation Matching & Ranking**  
   - Using a **CROSS JOIN** to evaluate all possible buyer-supplier matches.  
   - Implementing a **scoring system** based on:  
     - Exact & partial matches (grade, finish, thickness, width).  
     - Numeric tolerances for dimensions (e.g., width within ±10mm, thickness within ±0.5mm).  
   - Prioritizing **exact matches** over partial matches.  
   - Providing **match explanations** for transparency.  
   - Selecting **top 5 matches per buyer** based on rank.  

5. **Final Output Optimization**  
   - Creating a **view** in DuckDB to store and display top recommendations.  
   - Excluding redundant fields while ensuring structured output for easy integration with downstream applications.  
