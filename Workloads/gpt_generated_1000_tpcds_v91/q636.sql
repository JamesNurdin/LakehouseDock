WITH
    /* Sample a small fraction of inventory to reduce scan size */
    filtered_inventory AS (
        SELECT
            inv_date_sk,
            inv_item_sk,
            inv_warehouse_sk,
            inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (5)
        WHERE inv_quantity_on_hand > 0
          AND inv_warehouse_sk IN (1, 6, 12)
    ),
    /* Restrict catalog pages to a manageable subset */
    catalog_subset AS (
        SELECT
            cp_catalog_page_sk,
            cp_catalog_page_id,
            cp_start_date_sk,
            cp_end_date_sk,
            cp_department,
            cp_catalog_number,
            cp_type,
            cp_description
        FROM catalog_page
        WHERE cp_type = 'regular'
          AND cp_department IN ('Electronics', 'Clothing')
          AND cp_catalog_number BETWEEN 1 AND 1000
    ),
    /* Compute the overall average quantity – used later in a scalar sub‑query */
    overall_stats AS (
        SELECT AVG(inv_quantity_on_hand) AS overall_avg_qty
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    ),
    /* Aggregate totals per department and year (including subtotals via GROUPING SETS) */
    aggregated AS (
        SELECT
            c.cp_department               AS department,
            ds.d_year                     AS year,
            'total_quantity'              AS metric,
            SUM(i.inv_quantity_on_hand)   AS qty,
            CASE
                WHEN SUM(i.inv_quantity_on_hand) > 1000 THEN 'HIGH'
                WHEN SUM(i.inv_quantity_on_hand) > 500  THEN 'MEDIUM'
                ELSE 'LOW'
            END                           AS qty_category,
            0                             AS sort_order
        FROM catalog_subset c
        LEFT JOIN date_dim ds
            ON c.cp_start_date_sk = ds.d_date_sk
        LEFT JOIN filtered_inventory i
            ON i.inv_date_sk = ds.d_date_sk
        WHERE ds.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
          AND ds.d_weekend = 'N'
        GROUP BY GROUPING SETS (
            (c.cp_department, ds.d_year),
            (c.cp_department),
            (ds.d_year),
            ()
        )
    ),
    /* Rank departments by their total quantity */
    ranked AS (
        SELECT
            department,
            year,
            metric,
            qty,
            qty_category,
            ROW_NUMBER() OVER (PARTITION BY department ORDER BY qty DESC) AS rank_val,
            sort_order
        FROM aggregated
    ),
    /* Summary of average quantities, using CUBE for additional subtotals */
    summary AS (
        SELECT
            COALESCE(c.cp_department, 'ALL_DEPT') AS department,
            ds.d_year                           AS year,
            'average_quantity'                  AS metric,
            AVG(i.inv_quantity_on_hand)         AS qty,
            CASE
                WHEN AVG(i.inv_quantity_on_hand) > (SELECT overall_avg_qty FROM overall_stats)
                    THEN 'ABOVE_AVG'
                ELSE 'BELOW_AVG'
            END                                 AS qty_category,
            1                                   AS sort_order
        FROM catalog_subset c
        LEFT JOIN date_dim ds
            ON c.cp_start_date_sk = ds.d_date_sk
        LEFT JOIN filtered_inventory i
            ON i.inv_date_sk = ds.d_date_sk
        WHERE ds.d_fy_week_seq BETWEEN 10 AND 20
        GROUP BY CUBE (c.cp_department, ds.d_year)
    ),
    /* Union of detailed ranks and summary rows */
    final_set AS (
        SELECT department, year, metric, qty, rank_val, qty_category, sort_order
        FROM ranked
        UNION ALL
        SELECT department, year, metric, qty, NULL AS rank_val, qty_category, sort_order
        FROM summary
    )
SELECT
    department,
    year,
    metric,
    qty,
    rank_val,
    qty_category
FROM final_set
ORDER BY sort_order, department, year, metric, qty DESC
