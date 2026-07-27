WITH filtered_returns AS (
    SELECT
        cc.cc_name,
        r.r_reason_desc,
        cr.cr_return_amount,
        p.p_cost
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND regexp_like(p.p_channel_details, '(?i)available')
)
SELECT
    cc_name,
    r_reason_desc,
    COUNT(DISTINCT r_reason_desc) AS distinct_reason_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(p_cost) AS total_promo_cost,
    CONCAT(cc_name, ' - ', r_reason_desc) AS report_label
FROM filtered_returns
GROUP BY cc_name, r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 10
