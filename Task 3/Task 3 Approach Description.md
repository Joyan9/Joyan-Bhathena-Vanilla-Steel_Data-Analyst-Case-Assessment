# Task 3 Approach Description - Buyer Preference Matching

The task was aimed at matching supplier materials to buyer preferences and creating a recommendation table.

## **Approach**

I chose BigQuery as my database solution for this task because of its simplicity and its seamless integration with other Google services. 

1. I first converted the Excel files to Google Sheets for easier ingestion into BigQuery
2. Then created external tables in BigQuery pointing to these Google Sheets
3. Unified the supplier data and then applied the buyer preference matching logic

### Data Preparation

After examining the data, I noticed some challenges like
- Different schemas between supplier datasets
- Different formats for similar data (like finish types)
- Missing data in supplier_data2 (no thickness or width information)
- German descriptions for finishes needed translation

### Implementation Steps

**Step 1 - Unified Supplier Data**
I created a unified view of supplier data by:
- Standardized field names across both supplier datasets
- Handled NULL values
- Extracted finish information from descriptions in supplier_data2
- Added a unique material_id to each item for tracking (absent from supplier_1)
- Filtered out reserved items and those with zero quantity (Supplier_2 if reserved column contained `VANILLA` then assumed that the material was not available, reserved for another buyer)

**Step 2 - Buyer Preference Processing**
Buyer preferences did not have a lot of columns, therefore the processing steps were simpler:
- Created a standardized format for matching
- Added English translations for German finish descriptions
- Casted numeric values to appropriate types for comparison

**Step 3 - Recommendation Matching Logic**
I implemented the following matching logic between suppliers and buyer preferences:
- Used a CROSS JOIN to evaluate every possible buyer-supplier match
- Created a scoring system based on grade, finish, thickness, and width
- Implemented flexible matching for partial matches (using REGEXP_CONTAINS)
- Prioritized exact matches over partial matches
- Created detailed match explanations for transparency

**Step 4 - Output Optimization**
For the final output, I:
- Limited recommendations to the top 5 matches per buyer
- Included explanations for why each item was recommended
- Created a structured view for easier consumption by downstream applications

