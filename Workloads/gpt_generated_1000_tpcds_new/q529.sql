WITH eligible_warehouses AS (
    SELECT inv_warehouse_sk AS w_warehouse_sk
    FROM inventory
    GROUP BY inv_warehouse_sk
    EXCEPT
    SELECT cr_warehouse_sk
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    CONCAT(w.w_city, '-', w.w_state) AS location,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    lt.extracted_num
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN LATERAL (
    SELECT regexp_extract(cp.cp_description, '(\\d+)', 1) AS extracted_num
) AS lt
  ON true
WHERE cp.cp_type LIKE 'A%'
  AND regexp_like(cp.cp_description, '\\d{2}')
  AND cs.cs_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    )
  AND cs.cs_warehouse_sk IN (
        SELECT w_warehouse_sk
        FROM eligible_warehouses
    )
GROUP BY w.w_warehouse_id, w.w_city, w.w_state, lt.extracted_num
ORDER BY total_profit DESC
LIMIT 100
