WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 200
      AND inv_warehouse_sk IN (5, 8, 10)
    GROUP BY inv_date_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    s.s_state,
    w.web_name,
    i.inv_warehouse_sk,
    i.total_qty,
    CASE
        WHEN i.total_qty >= 800 THEN 'High'
        WHEN i.total_qty >= 400 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY i.total_qty DESC) AS state_qty_rank,
    RANK() OVER (ORDER BY i.total_qty DESC) AS overall_qty_rank
FROM inv_agg i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_moy = 5
  AND s.s_gmt_offset = -5.00
  AND w.web_class = 'Retail'
ORDER BY i.total_qty DESC
LIMIT 100
