-- Returns metadata for the specified project and dataset.
-- SELECT * FROM upheld-setting-420306.deals_vanilla_steel.INFORMATION_SCHEMA.TABLES;
/*
This SQL model consolidates supplier data from supplier1 and supplier2 into a unified table, standardizing attributes like grade, finish, thickness, weight, and quantity for the next step of buyer-supplier matching
*/
CREATE OR REPLACE TABLE `upheld-setting-420306.deals_vanilla_steel.unified_supplier_data` AS

-- Supplier Data 1
SELECT
  'supplier_1' AS source,
  `Quality_Choice` AS quality,
  Grade AS grade,
  Finish AS finish,
  CAST(`Thickness__mm_` AS FLOAT64) AS thickness_mm,
  CAST(`Width__mm_` AS FLOAT64) AS width_mm, 
  Description AS description,
  CAST(`Gross_weight__kg_` AS FLOAT64) AS weight_kg,
  CAST(Quantity AS INT64) AS quantity,
  CONCAT('S1-', GENERATE_UUID()) AS material_id -- assigning an ID such that recommendations can be linked back to the unified_supplier_data
FROM
  `upheld-setting-420306.deals_vanilla_steel.supplier_data1`
WHERE
  Quantity > 0  -- Only include items with available quantity

UNION ALL -- union all keeps duplicate rows as well

-- Supplier Data 2
SELECT
  'supplier_2' AS source,
  'NA' AS quality,
  Material AS grade,  -- Using Material as grade
  LOWER(REGEXP_REPLACE(Description, 'Material is ', '')) AS finish, -- Extract finish from description
  -- supplier2 does not have thickness and width values - setting as NULL 
  NULL AS thickness_mm, 
  NULL AS width_mm,
  Description AS description,
  CAST(Weight__kg_ AS FLOAT64) AS weight_kg,
  CAST(Quantity AS INT64) AS quantity,
  CAST(Article_ID AS STRING) AS material_id
FROM
  `upheld-setting-420306.deals_vanilla_steel.supplier_data2`
WHERE
  Reserved != 'VANILLA'  -- Only include non-reserved items. I'm assuming here that 'Vanilla' refers to the material being reserved for another buyer
