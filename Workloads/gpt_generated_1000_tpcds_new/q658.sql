WITH
    monthly_pages AS (
        SELECT cp.cp_catalog_page_id
        FROM catalog_page cp
        WHERE cp.cp_type = 'monthly'
    ),
    biannual_pages AS (
        SELECT cp.cp_catalog_page_id
        FROM catalog_page cp
        WHERE cp.cp_type = 'bi-annual'
    ),
    target_pages AS (
        SELECT cp_catalog_page_id
        FROM monthly_pages
        EXCEPT
        SELECT cp_catalog_page_id FROM biannual_pages
    ),
    joined AS (
        SELECT
            cp.cp_department,
            CASE
                WHEN i.inv_quantity_on_hand > 500 THEN 'High'
                WHEN i.inv_quantity_on_hand > 200 THEN 'Medium'
                ELSE 'Low'
            END AS qty_category,
            i.inv_quantity_on_hand
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        JOIN (
            SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
        ) i ON i.inv_date_sk = d.d_date_sk
        WHERE cp.cp_catalog_page_id IN (SELECT cp_catalog_page_id FROM target_pages)
          AND cp.cp_type = 'monthly'
          AND d.d_current_month = 'Y'
          AND i.inv_quantity_on_hand > 100
          AND d.d_year = 2023
          AND cp.cp_department IS NOT NULL
    ),
    agg1 AS (
        SELECT
            cp_department,
            qty_category,
            SUM(inv_quantity_on_hand) AS total_qty,
            COUNT(*) AS item_cnt
        FROM joined
        GROUP BY cp_department, qty_category
        HAVING SUM(inv_quantity_on_hand) > 200
    ),
    final_agg AS (
        SELECT
            qty_category,
            AVG(total_qty) AS avg_total_qty,
            SUM(item_cnt) AS total_items
        FROM agg1
        GROUP BY qty_category
        HAVING AVG(total_qty) > 150
    )
SELECT
    qty_category,
    avg_total_qty,
    total_items
FROM final_agg
ORDER BY avg_total_qty DESC
OFFSET 10 ROWS
LIMIT 100
