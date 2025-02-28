CREATE OR REPLACE TABLE `upheld-setting-420306.deals_vanilla_steel.buyer_recommendations` AS

WITH 
  -- standardising the buyer_preferences
  buyer_prefs AS (
SELECT
  `Buyer_ID` AS buyer_id,
  `Preferred_Grade` AS preferred_grade,
  `Preferred_Finish` AS preferred_finish,
  CASE
    WHEN `Preferred_Finish` = 'gebeizt' THEN 'pickled'
    WHEN `Preferred_Finish` = 'gebeizt und geglüht' THEN 'pickled and annealed'
    WHEN `Preferred_Finish` = 'ungebeizt' THEN 'unpickled'
    ELSE `Preferred_Finish`
  END AS preferred_finish_english,
  CAST(`Preferred_Thickness__mm_` AS FLOAT64) AS preferred_thickness_mm,
  CAST(`Preferred_Width__mm_` AS FLOAT64) AS preferred_width_mm,
  CAST(`Max_Weight__kg_` AS FLOAT64) AS max_weight_kg,
  CAST(`Min_Quantity` AS INT64) AS min_quantity
FROM
  `upheld-setting-420306.deals_vanilla_steel.buyer_preferences`
)
SELECT
  b.buyer_id,
  s.material_id,
  s.source AS supplier_source,
  s.grade,
  s.finish,
  s.thickness_mm,
  s.width_mm,
  s.weight_kg,
  s.quantity,
  -- Calculate a match score to rank recommendations (the higher score, the better)
  CASE 
    WHEN s.grade = b.preferred_grade THEN 100 ELSE 0  -- Exact grade match
  END +
  CASE 
    WHEN s.finish = b.preferred_finish THEN 50 ELSE 0  -- Exact finish match
  END +
  CASE 
    -- Thickness close to preference gets a higher score
    WHEN ABS(IFNULL(s.thickness_mm, 0) - b.preferred_thickness_mm) < 0.5 THEN 50
    WHEN ABS(IFNULL(s.thickness_mm, 0) - b.preferred_thickness_mm) < 1.0 THEN 25
    ELSE 0 
  END +
  CASE 
    -- Width close to preference gets a higher score
    WHEN ABS(IFNULL(s.width_mm, 0) - b.preferred_width_mm) < 10 THEN 30
    WHEN ABS(IFNULL(s.width_mm, 0) - b.preferred_width_mm) < 20 THEN 15
    ELSE 0 
  END AS match_score,

  -- Generate a textual explanation of why this material was recommended
  CONCAT(
    'Grade match: ', IF(s.grade = b.preferred_grade, 'Yes', 'No'), 
    ', Finish match: ', IF(s.finish = b.preferred_finish, 'Yes', 'No'),
    ', Thickness diff: ', ROUND(ABS(IFNULL(s.thickness_mm, 0) - b.preferred_thickness_mm), 2), ' mm',
    ', Width diff: ', ROUND(ABS(IFNULL(s.width_mm, 0) - b.preferred_width_mm), 2), ' mm'
  ) AS match_reason
  
FROM
  buyer_prefs b
-- Using CROSS JOIN to match every buyer with every supplier material option
CROSS JOIN
  `upheld-setting-420306.deals_vanilla_steel.unified_supplier_data` s
WHERE
  -- Matching criteria
  (
    -- Either grade matches exactly OR 
    -- Supplier grade contains buyer's preferred grade (partial match)
    s.grade = b.preferred_grade 
    OR REGEXP_CONTAINS(s.grade, b.preferred_grade)
  )
  AND 
  (
    -- Either finish matches exactly OR
    -- Supplier finish contains buyer's preferred finish (partial match) OR
    -- No finish preference or finish data unavailable
    s.finish = b.preferred_finish 
    OR REGEXP_CONTAINS(IFNULL(s.finish, ''), b.preferred_finish)
    OR b.preferred_finish IS NULL 
    OR s.finish IS NULL
  ) 
  AND 
  (
    -- Weight is under max OR no weight preference
    s.weight_kg <= b.max_weight_kg 
    OR b.max_weight_kg IS NULL
  ) 
  AND 
  (
    -- Quantity meets minimum OR no quantity preference
    s.quantity >= b.min_quantity 
    OR b.min_quantity IS NULL
  )
QUALIFY
  -- Only keep top 5 matches per buyer
  ROW_NUMBER() OVER (PARTITION BY b.buyer_id ORDER BY match_score DESC) <= 5
ORDER BY
  b.buyer_id, match_score DESC
