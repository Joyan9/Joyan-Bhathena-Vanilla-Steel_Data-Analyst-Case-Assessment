/*
This model outputs a dataset for the buyer company performance report. 
Metrics: total deals, revenue, profit, deal types, and purchase patterns, segmented by time dimensions like month, year, and quarter.
*/

SELECT
  -- Company information
  buyer_company_id as `Buyer ID`, 
  buyer_company as `Buyer Company`,  
  buyer_region as `Region`,  
  buyer_country as `Country`,  
 
  -- Time dimensions
  DATE_TRUNC(deal_created_at, MONTH) as `Month`,  
  EXTRACT(YEAR FROM deal_created_at) as `Year`, 
  EXTRACT(QUARTER FROM deal_created_at) as `Quarter`, 
 
  -- Deal counts and types
  COUNT(DISTINCT deal_id) as `Total Deals`,  -- Total number of distinct deals for the buyer
  COUNT(DISTINCT CASE WHEN deal_type = 'trading' THEN deal_id END) as `Trading Deals`,  -- Number of trading deals
  COUNT(DISTINCT CASE WHEN deal_type = 'agent' THEN deal_id END) as `Agent Deals`,  -- Number of agent deals
 
  -- Volume metrics
  SUM(confirmed_tonnage) as `Total Tonnage`, 
  AVG(confirmed_tonnage) as `Avg Deal Size Tons`, 
 
  -- Financial metrics
  SUM(confirmed_gross_revenue) as `Total Revenue`,  
  SUM(confirmed_gross_profit) as `Total Profit`, 
 
  -- Calculated Profit Margin
  CASE
    WHEN SUM(confirmed_gross_revenue) > 0
    THEN (SUM(confirmed_gross_profit) / SUM(confirmed_gross_revenue)) * 100  -- Profit margin percentage
    ELSE 0
  END as `Profit Margin %`,
 
  -- Purchase patterns
  COUNT(DISTINCT supplier_company_id) as `Unique Suppliers`,  -- Number of unique suppliers involved with the buyer
  SUM(confirmed_gross_revenue) / COUNT(DISTINCT deal_id) as `Average Deal Value`,  -- Average value per deal
 
  -- Time-based metrics
  MIN(deal_created_at) as `First Purchase Date`,  -- Date of the first purchase made by the buyer
  MAX(deal_created_at) as `Most Recent Purchase`,  -- Date of the most recent purchase made by the buyer
  COUNT(DISTINCT DATE_TRUNC(deal_created_at, MONTH)) as `Active Months`  -- Number of distinct months the buyer made purchases
FROM `deals_vanilla_steel.deals`
WHERE buyer_company IS NOT NULL  -- Ensuring only deals with a non-null buyer company are included
GROUP BY
  buyer_company_id, 
  buyer_company,
  buyer_region, 
  buyer_country,  
  DATE_TRUNC(deal_created_at, MONTH), 
  EXTRACT(YEAR FROM deal_created_at), 
  EXTRACT(QUARTER FROM deal_created_at)  
ORDER BY `Year`, `Month`, `Total Revenue` DESC 
