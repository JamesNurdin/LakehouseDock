WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_net_loss,
        r.r_reason_desc,
        i.i_item_desc,
        i.i_color,
        i.i_product_name,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'Did not like')
      AND i.i_color LIKE 'Red%'
)
SELECT
    fr.w_warehouse_name,
    fr.w_city,
    fr.w_state,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(fr.cr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(fr.cr_net_loss) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    regexp_extract(MIN(fr.r_reason_desc), '(Did not like.*)', 1) AS example_reason
FROM filtered_returns fr
GROUP BY fr.w_warehouse_name, fr.w_city, fr.w_state
HAVING SUM(fr.cr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 20
