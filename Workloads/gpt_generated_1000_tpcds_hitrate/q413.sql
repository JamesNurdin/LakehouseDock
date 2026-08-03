WITH merged_sales_returns AS (
    SELECT
        COALESCE(cs.cs_sold_date_sk, cr.cr_returned_date_sk) AS date_sk,
        COALESCE(cs.cs_ship_mode_sk, cr.cr_ship_mode_sk) AS ship_mode_sk,
        cs.cs_net_paid,
        cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),

sales_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_ship_mode_id AS group_key,
        'SalesNet' AS category,
        SUM(COALESCE(m.cs_net_paid, 0)) AS amount,
        CASE WHEN SUM(COALESCE(m.cs_net_paid, 0)) > 10000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM merged_sales_returns m
    JOIN date_dim d ON m.date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm ON m.ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    )
    GROUP BY ROLLUP (d.d_year, sm.sm_ship_mode_id)
),

inventory_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS group_key,
        'InventoryQty' AS category,
        SUM(i.inv_quantity_on_hand) AS amount,
        CASE WHEN SUM(i.inv_quantity_on_hand) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_access_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    )
    GROUP BY ROLLUP (d.d_year, w.w_warehouse_name)
)
SELECT *
FROM (
    SELECT year, group_key, category, amount, amount_category
    FROM sales_agg
    UNION ALL
    SELECT year, group_key, category, amount, amount_category
    FROM inventory_agg
) combined
ORDER BY year DESC, amount DESC
LIMIT 100
