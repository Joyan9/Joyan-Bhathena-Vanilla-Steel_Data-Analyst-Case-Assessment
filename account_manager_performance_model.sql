/*
This model outputs a dataset that can be used for analyzing Account Managers' performance.
It aggregates deal.csv data from both the buyer and supplier side AMs, and calculates the attribution factor (AM share),
and provides metrics related to tonnage, revenue, profit, and regions served.
*/

WITH am_deals AS (
  SELECT
    deal_id,
    deal_created_at,
    DATE_TRUNC(deal_created_at, MONTH) AS deal_month,
    EXTRACT(YEAR FROM deal_created_at) AS deal_year,
   
    -- AM Information
    buyer_am AS am_name,
    buyer_am_id AS am_id,
    'Buyer Side' AS am_role,
    buyer_region AS region,
   
    -- Deal Metrics
    confirmed_tonnage,
    confirmed_gross_revenue,
    confirmed_gross_profit,
    confirmed_gross_profit_margin,
   
    -- Attribution calculation
    CASE
      WHEN buyer_am_id = supplier_am_id THEN 1.0  -- Same AM on both sides
      ELSE 0.5  -- AM only on buyer side
    END AS attribution_factor
   
  FROM `deals_vanilla_steel.deals`
  WHERE buyer_am_id IS NOT NULL
 
  UNION ALL -- Combining results from both the buyer and supplier sides
 
  SELECT
    deal_id,
    deal_created_at,
    DATE_TRUNC(deal_created_at, MONTH) AS deal_month,
    EXTRACT(YEAR FROM deal_created_at) AS deal_year,
   
    -- AM Information
    supplier_am AS am_name,
    supplier_am_id AS am_id,
    'Supplier Side' AS am_role,
    supplier_region AS region,
   
    -- Deal Metrics
    confirmed_tonnage,
    confirmed_gross_revenue,
    confirmed_gross_profit,
    confirmed_gross_profit_margin,
   
    -- Attribution calculation
    CASE
      WHEN supplier_am_id = buyer_am_id THEN 1.0  -- Same AM on both sides
      ELSE 0.5  -- AM only on supplier side
    END AS attribution_factor
   
  FROM `deals_vanilla_steel.deals`
  WHERE supplier_am_id IS NOT NULL
)


-- Final aggregated Account Manager performance dataset
SELECT
  am_id as `AM ID`,
  am_name as `Account Manager`,
  deal_month as `Month`,
  deal_year as `Year`,
 
  -- Count metrics
  COUNT(DISTINCT deal_id) AS `Total Deals`,
  COUNT(DISTINCT CASE WHEN attribution_factor = 1.0 THEN deal_id END) AS `Full Attribution Deals`,
  COUNT(DISTINCT CASE WHEN attribution_factor = 0.5 THEN deal_id END) AS `Partial Attribution Deals`,
 
  -- Volume metrics
  SUM(confirmed_tonnage * attribution_factor) AS `Attributed Tonnage`,
 
  -- Financial metrics
  SUM(confirmed_gross_revenue * attribution_factor) AS `Attributed Revenue`,
  SUM(confirmed_gross_profit * attribution_factor) AS `Attributed Profit`,
 
  -- Calculated metrics
  CASE
    WHEN SUM(confirmed_gross_revenue * attribution_factor) > 0
    THEN (SUM(confirmed_gross_profit * attribution_factor) / SUM(confirmed_gross_revenue * attribution_factor))
    ELSE 0
  END AS `Profit Margin%`,
 
  -- Additional context
  STRING_AGG(DISTINCT region, ', ') AS `Regions Served`,
  COUNT(DISTINCT region) AS `Total Regions Served`,
  COUNT(DISTINCT CASE WHEN am_role = 'Buyer Side' THEN deal_id END) AS `Buyer Side Deals`,
  COUNT(DISTINCT CASE WHEN am_role = 'Supplier Side' THEN deal_id END) AS `Supplier Side Deals`
 
FROM am_deals
GROUP BY am_id, am_name, deal_month, deal_year
