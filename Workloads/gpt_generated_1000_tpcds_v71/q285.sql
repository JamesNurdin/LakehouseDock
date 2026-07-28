WITH inv_agg AS (
        SELECT inv_date_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        WHERE inv_quantity_on_hand > 100
        GROUP BY inv_date_sk, inv_warehouse_sk
    ),
    union_inventory AS (
        SELECT inv_date_sk,
               inv_warehouse_sk,
               total_qty
        FROM inv_agg
        WHERE inv_warehouse_sk IN (2, 8)
        UNION ALL
        SELECT inv_date_sk,
               inv_warehouse_sk,
               total_qty
        FROM inv_agg
        WHERE total_qty BETWEEN 200 AND 500
    ),
    store_filtered AS (
        SELECT s_store_sk,
               s_store_name,
               s_market_id,
               s_gmt_offset,
               s_closed_date_sk
        FROM store
        WHERE s_market_id IN (1, 3, 5)
          AND s_gmt_offset >= -7.00
    )
SELECT
    d.d_date,
    s.s_store_name,
    s.s_market_id,
    ui.inv_warehouse_sk,
    ui.total_qty,
    RANK() OVER (PARTITION BY s.s_market_id ORDER BY ui.total_qty DESC) AS market_qty_rank,
    CASE
        WHEN d.d_day_name = 'Monday'   THEN 'Start of week'
        WHEN d.d_day_name = 'Friday'   THEN 'End of week'
        ELSE 'Midweek'
    END AS day_category
FROM union_inventory ui
JOIN date_dim d ON ui.inv_date_sk = d.d_date_sk
JOIN store_filtered s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_current_month = 'Y'
  AND d.d_day_name IN ('Monday', 'Friday', 'Sunday')
  AND s.s_gmt_offset <> -8.00
  AND ui.total_qty > 150
  AND EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_store_sk = s.s_store_sk
          AND s2.s_market_desc IS NOT NULL
    )
ORDER BY s.s_market_id, market_qty_rank
LIMIT 100
