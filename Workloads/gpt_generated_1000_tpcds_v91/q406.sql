WITH inv_agg AS (
    SELECT inv.inv_warehouse_sk,
           inv.inv_date_sk,
           SUM(inv.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY inv.inv_warehouse_sk, inv.inv_date_sk
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    ws.web_name,
    SUM(ia.qty_on_hand) AS total_qty,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ia.qty_on_hand) DESC) AS rank_within_year,
    CASE WHEN ws.web_name IS NULL THEN 'No Site' ELSE ws.web_name END AS site_name_flag
FROM inv_agg ia
JOIN date_dim d
    ON ia.inv_date_sk = d.d_date_sk
JOIN warehouse w
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
    AND ws.web_company_id IN (4,5)
WHERE d.d_fy_year = 1914
  AND d.d_following_holiday = 'N'
  AND w.w_city IN ('Pleasant Grove','Fairview')
GROUP BY ROLLUP (w.w_warehouse_name, d.d_year, ws.web_name)
HAVING SUM(ia.qty_on_hand) > 0
ORDER BY total_qty DESC
OFFSET 0
LIMIT 100
