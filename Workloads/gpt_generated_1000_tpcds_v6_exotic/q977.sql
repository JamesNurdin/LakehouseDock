WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_reason_sk,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND regexp_like(cc.cc_manager, '^W')
      AND regexp_like(cc.cc_city, 'Hill')
)
SELECT
    cc.cc_name AS call_center_name,
    r.r_reason_desc AS return_reason,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    MIN(regexp_extract(cc.cc_manager, '^([^ ]+)')) AS manager_first_name,
    CONCAT(cc.cc_name, ' - ', r.r_reason_desc) AS combined_label
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = fr.cr_order_number
      AND wr.wr_net_loss > 0
)
  AND r.r_reason_desc LIKE '%damage%'
GROUP BY ROLLUP (cc.cc_name, r.r_reason_desc)
ORDER BY total_net_loss DESC NULLS LAST
