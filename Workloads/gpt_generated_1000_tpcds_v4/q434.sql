WITH filtered_catalog_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_name,
        r.r_reason_desc,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(cc.cc_name, '^.*Center.*$')
      AND r.r_reason_desc LIKE 'Customer%'
)
SELECT
    cc_call_center_id,
    cc_city,
    CONCAT('CC_', SUBSTRING(cc_name, 1, 3)) AS name_prefix,
    SUM(cr_net_loss) AS total_net_loss,
    SUM(cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cr_order_number) AS distinct_orders
FROM filtered_catalog_returns
GROUP BY
    cc_call_center_id,
    cc_city,
    CONCAT('CC_', SUBSTRING(cc_name, 1, 3))
ORDER BY total_net_loss DESC
LIMIT 100
