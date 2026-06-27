WITH cp_active AS (
    SELECT
        cp.cp_catalog_page_id,
        d_start.d_date AS start_date,
        d_end.d_date   AS end_date
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    i.i_category,
    i.i_brand,
    SUM(inv.inv_quantity_on_hand)          AS total_quantity,
    AVG(i.i_current_price)                 AS avg_price,
    COUNT(DISTINCT cp_active.cp_catalog_page_id) AS distinct_catalog_pages
FROM inventory inv
JOIN item i        ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w   ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN cp_active     ON d_inv.d_date BETWEEN cp_active.start_date AND cp_active.end_date
WHERE d_inv.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND i.i_category = 'Sports'
GROUP BY w.w_warehouse_id, w.w_city, i.i_category, i.i_brand
ORDER BY total_quantity DESC
LIMIT 10
