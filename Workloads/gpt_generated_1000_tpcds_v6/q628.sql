WITH catalog_returns_enhanced AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        d.d_date,
        date_format(date_trunc('month', d.d_date), '%Y-%m') AS month_str,
        cr.cr_net_loss,
        cc.cc_name
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE w.w_city LIKE '%York%'
      AND regexp_like(cc.cc_name, 'Center$')
)
SELECT
    c.w_warehouse_name,
    c.month_str,
    CONCAT(c.w_warehouse_name, ' - ', c.month_str) AS warehouse_month,
    MAX(CASE WHEN regexp_like(c.w_city, '^New.*') THEN 'New' ELSE 'Other' END) AS city_category,
    SUM(c.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM catalog_returns_enhanced c
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_warehouse_sk = c.w_warehouse_sk
      AND i.inv_quantity_on_hand > 1000
)
GROUP BY ROLLUP (c.w_warehouse_name, c.month_str)
ORDER BY c.w_warehouse_name, c.month_str
LIMIT 100
