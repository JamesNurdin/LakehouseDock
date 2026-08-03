WITH filtered_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
    WHERE regexp_like(i_item_desc, '(?i)cool|smart')
)
SELECT
    r.r_reason_id,
    cp.cp_department,
    sm.sm_carrier,
    w.w_warehouse_name,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_qty,
    SUM(CASE WHEN cr.cr_net_loss > 100 THEN cr.cr_net_loss ELSE 0 END) AS high_loss_sum,
    CONCAT(i.i_brand, '-', i.i_color) AS item_code,
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r.r_reason_sk
    ) AS avg_return_amount_by_reason
FROM catalog_returns cr
JOIN filtered_items i
    ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE r.r_reason_desc LIKE '%product%'
  AND regexp_like(r.r_reason_desc, '(?i)service|location')
GROUP BY
    r.r_reason_id,
    cp.cp_department,
    sm.sm_carrier,
    w.w_warehouse_name,
    i.i_brand,
    i.i_color,
    i.i_item_desc,
    r.r_reason_sk
ORDER BY total_return_amount DESC
LIMIT 100
