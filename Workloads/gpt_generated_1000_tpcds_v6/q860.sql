WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_order_number,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)size')
      AND cp.cp_description LIKE 'Gift%'
)
SELECT
    CONCAT(w.w_city, ', ', w.w_state) AS warehouse_location,
    REGEXP_EXTRACT(cp.cp_catalog_page_id, '(\\d+)$') AS page_id_suffix,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT fr.cr_order_number) AS returns_cnt
FROM filtered_returns fr
JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY
    w.w_city,
    w.w_state,
    cp.cp_catalog_page_id
HAVING SUM(fr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
