WITH filtered_returns AS (
    SELECT
        cc.cc_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        cr.cr_net_loss,
        regexp_extract(r.r_reason_desc, 'Did not like the (.*)', 1) AS disliked_feature,
        substring(cc.cc_name, 1, 3) AS name_prefix
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '^Did not like')
      AND cc.cc_city LIKE 'A%'
      AND w.w_country LIKE 'U%'
      AND regexp_like(cc.cc_name, '^[A-Z]{3}')
)
SELECT
    name_prefix,
    cc_name,
    w_warehouse_name,
    r_reason_desc,
    disliked_feature,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM filtered_returns
GROUP BY
    name_prefix,
    cc_name,
    w_warehouse_name,
    r_reason_desc,
    disliked_feature
HAVING SUM(cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
