/*
This view aggregates the top 5 material recommendations for each buyer, based on match score, and counts the total number of distinct recommended materials.
*/

CREATE OR REPLACE VIEW `upheld-setting-420306.deals_vanilla_steel.buyer_recommendations_view` AS

SELECT
  buyer_id,  -- The ID of the buyer for whom the recommendations are made
  ARRAY_AGG(  -- Aggregate recommended materials into an array for each buyer
    STRUCT(  
      material_id,  
      supplier_source,  
      grade, 
      finish,  
      thickness_mm, 
      width_mm, 
      weight_kg, 
      quantity,
      match_score, 
      match_reason 
    )
    ORDER BY match_score DESC 
    LIMIT 5 
  ) AS recommended_materials, 
  COUNT(DISTINCT material_id) AS total_recommendations 
FROM
  `upheld-setting-420306.deals_vanilla_steel.buyer_recommendations`  
GROUP BY
  buyer_id  -- Group by buyer so that we get one row per buyer
