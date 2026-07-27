WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_catalog_page_sk
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)years')
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
),
inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    r.r_reason_desc,
    ia.total_qty_on_hand,
    COUNT(*) AS return_count,
    SUM(fr.cr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(CASE WHEN fr.cr_return_amt_inc_tax > 1000 THEN fr.cr_return_amt_inc_tax ELSE 0 END) AS high_value_return,
    CONCAT(w.w_city, ', ', w.w_state) AS location
FROM filtered_returns fr
JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory_agg ia
    ON w.w_warehouse_sk = ia.inv_warehouse_sk
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    r.r_reason_desc,
    ia.total_qty_on_hand,
    w.w_city,
    w.w_state
HAVING COUNT(*) >= 5
ORDER BY total_return_inc_tax DESC
LIMIT 100
