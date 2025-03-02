from load_resources import download_convert_to_csv, load_data_to_duckdb
import duckdb

if __name__ == '__main__':
    # download the raw xlsx files and store them as CSVs
    csv_files = download_convert_to_csv()

    # load the CSV files into DuckDB as tables
    database_name = 'task3.duckdb'
    schema_name = 'task_3_data'
    load_data_to_duckdb(csv_files, database_name)

    # Create a DuckDB connection and database
    conn = duckdb.connect(database_name)

    unified_supplier_dataset_query = f"""
        -- unified_supplier_data
        CREATE OR REPLACE TABLE unified_supplier_data AS

        WITH supplier_data1 AS (
        SELECT
            'supplier_1' AS source,
            "Quality/Choice" AS quality,
            Grade AS grade,
            Finish AS finish,
            CAST("Thickness (mm)" AS FLOAT) AS thickness_mm,
            CAST("Width (mm)" AS FLOAT) AS width_mm,
            Description AS description,
            CAST("Gross weight (kg)" AS FLOAT) AS weight_kg,
            CAST(Quantity AS BIGINT) AS quantity
        FROM {schema_name}.supplier_data1
        WHERE Quantity > 0
        ),

        supplier_data2 AS (
        SELECT
            'supplier_2' AS source,
            'NA' AS quality,
            Material AS grade,
            LOWER(REGEXP_REPLACE(Description, 'Material is ', '')) AS finish,
            NULL AS thickness_mm,  -- supplier2 doesn't have thickness and width values
            NULL AS width_mm,
            Description AS description,
            CAST("Weight (kg)" AS FLOAT) AS weight_kg,
            CAST(Quantity AS BIGINT) AS quantity
        FROM {schema_name}.supplier_data2
        WHERE Reserved != 'VANILLA'
        )

        -- Now combine data from both suppliers
        SELECT * FROM supplier_data1
        UNION ALL
        SELECT * FROM supplier_data2;
    """

    conn.execute(unified_supplier_dataset_query)


    buyer_recommendations_query = f""" 
            /*
            This SQL model generates ranked buyer recommendations for materials by matching buyer preferences with supplier data based on grade, finish, dimensions, and availability.
            */

            DROP TABLE IF EXISTS buyer_recommendations;
            CREATE TABLE buyer_recommendations AS

            WITH 
            -- standardising the buyer_preferences
            buyer_prefs AS (
            SELECT
                "Buyer ID" AS buyer_id,
                "Preferred Grade" AS preferred_grade,
                "Preferred Finish" AS preferred_finish,
                CASE
                    WHEN "Preferred Finish" = 'gebeizt' THEN 'pickled'
                    WHEN "Preferred Finish" = 'gebeizt und geglüht' THEN 'pickled and annealed'
                    WHEN "Preferred Finish" = 'ungebeizt' THEN 'unpickled'
                    ELSE "Preferred Finish"
                END AS preferred_finish_english,
                CAST("Preferred Thickness (mm)" AS FLOAT) AS preferred_thickness_mm,
                CAST("Preferred Width (mm)" AS FLOAT) AS preferred_width_mm,
                CAST("Max Weight (kg)" AS FLOAT) AS max_weight_kg,
                CAST("Min Quantity" AS INTEGER) AS min_quantity
            FROM task_3_data.buyer_preferences
            ),

            -- Create a base matching query with all potential matches and their scores
            base_matches AS (
            SELECT
                b.buyer_id,
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
                    WHEN ABS(COALESCE(s.thickness_mm, 0) - b.preferred_thickness_mm) < 0.5 THEN 50
                    WHEN ABS(COALESCE(s.thickness_mm, 0) - b.preferred_thickness_mm) < 1.0 THEN 25
                    ELSE 0 
                END +
                CASE 
                    -- Width close to preference gets a higher score
                    WHEN ABS(COALESCE(s.width_mm, 0) - b.preferred_width_mm) < 10 THEN 30
                    WHEN ABS(COALESCE(s.width_mm, 0) - b.preferred_width_mm) < 20 THEN 15
                    ELSE 0 
                END AS match_score,

                -- Generate a textual explanation of why this material was recommended
                CONCAT(
                    'Grade match: ', CASE WHEN s.grade = b.preferred_grade THEN 'Yes' ELSE 'No' END, 
                    ', Finish match: ', CASE WHEN s.finish = b.preferred_finish THEN 'Yes' ELSE 'No' END,
                    ', Thickness diff: ', ROUND(ABS(COALESCE(s.thickness_mm, 0) - b.preferred_thickness_mm), 2), ' mm',
                    ', Width diff: ', ROUND(ABS(COALESCE(s.width_mm, 0) - b.preferred_width_mm), 2), ' mm'
                ) AS match_reason,
                
                -- Add a rank for filtering top 5 per buyer
                ROW_NUMBER() OVER (PARTITION BY b.buyer_id ORDER BY 
                CASE 
                    WHEN s.grade = b.preferred_grade THEN 100 ELSE 0
                END +
                CASE 
                    WHEN s.finish = b.preferred_finish THEN 50 ELSE 0
                END +
                CASE 
                    WHEN ABS(COALESCE(s.thickness_mm, 0) - b.preferred_thickness_mm) < 0.5 THEN 50
                    WHEN ABS(COALESCE(s.thickness_mm, 0) - b.preferred_thickness_mm) < 1.0 THEN 25
                    ELSE 0 
                END +
                CASE 
                    WHEN ABS(COALESCE(s.width_mm, 0) - b.preferred_width_mm) < 10 THEN 30
                    WHEN ABS(COALESCE(s.width_mm, 0) - b.preferred_width_mm) < 20 THEN 15
                    ELSE 0 
                END DESC) AS rank_num
            FROM
                buyer_prefs b
                -- Using CROSS JOIN to match every buyer with every supplier material option
                CROSS JOIN
                unified_supplier_data s
            WHERE
                -- Matching criteria
                (
                    -- Either grade matches exactly OR 
                    -- Supplier grade contains buyer's preferred grade (partial match)
                    s.grade = b.preferred_grade 
                    OR s.grade LIKE '%' || b.preferred_grade || '%'
                )
                AND 
                (
                    -- Either finish matches exactly OR
                    -- Supplier finish contains buyer's preferred finish (partial match) OR
                    -- No finish preference or finish data unavailable
                    s.finish = b.preferred_finish 
                    OR COALESCE(s.finish, '') LIKE '%' || b.preferred_finish || '%'
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
            )

            -- Select only top 5 matches per buyer
            SELECT
            buyer_id,
            supplier_source,
            grade,
            finish,
            thickness_mm,
            width_mm,
            weight_kg,
            quantity,
            match_score,
            match_reason
            FROM 
            base_matches
            WHERE 
            rank_num <= 5
            ORDER BY
            buyer_id, match_score DESC;
                """

    conn.execute(buyer_recommendations_query)


    final_recommendations_query = f""" 
        /*
        This view aggregates the top 5 material recommendations for each buyer, 
        based on match score, and counts the total number of distinct recommended materials.
        */
        DROP VIEW IF EXISTS buyer_recommendations_view;
        CREATE VIEW buyer_recommendations_view AS
        
        WITH ranked_recommendations AS (
        SELECT
            buyer_id,
            supplier_source,
            grade,
            finish,
            thickness_mm,
            width_mm,
            weight_kg,
            quantity,
            match_score,
            match_reason,
            ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY match_score DESC) AS rank_num
        FROM
            buyer_recommendations
        ),
        top_recommendations AS (
        SELECT
            *
        FROM
            ranked_recommendations
        WHERE
            rank_num <= 5
        )
        SELECT
            * EXCLUDE (match_score)
        FROM
        top_recommendations
        --GROUP BY buyer_id;
    """

    conn.execute(final_recommendations_query)

    print("Following are the top 5 recommendations for each buyer:")

    print(conn.execute("""SELECT * FROM buyer_recommendations_view;""").fetch_df())

    conn.close()

    