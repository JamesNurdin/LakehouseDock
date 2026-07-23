WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv_item_sk) AS distinct_item_count,
        AVG(inv_quantity_on_hand) AS avg_quantity_per_item
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_item_sk IN (101440, 101420, 101449)
      AND inv_warehouse_sk IN (1, 8, 14, 16, 17)
    GROUP BY inv_date_sk, inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d.d_date,
    d.d_day_name,
    inv_agg.total_quantity,
    inv_agg.distinct_item_count,
    inv_agg.avg_quantity_per_item,
    (
        SELECT MAX(i.inv_quantity_on_hand)
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
    ) AS max_quantity_any_date,
    ROW_NUMBER() OVER (ORDER BY inv_agg.total_quantity DESC) AS warehouse_quantity_rank
FROM inv_agg
JOIN date_dim d ON inv_agg.inv_date_sk = d.d_date_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_current_month = 'Y'
  AND d.d_year = 1998
  AND d.d_dom BETWEEN 5 AND 20
  AND w.w_county = 'Mobile County'
  AND w.w_street_type = 'Ave'
ORDER BY inv_agg.total_quantity DESC
LIMIT 100
