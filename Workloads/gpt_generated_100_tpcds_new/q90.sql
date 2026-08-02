WITH intersect_keys AS (
    SELECT cr_call_center_sk AS key
    FROM catalog_returns
    WHERE cr_return_amount > 500
    INTERSECT
    SELECT cc_call_center_sk AS key
    FROM call_center
    WHERE cc_state = 'CA' AND cc_gmt_offset = -8.00
)
SELECT
    cc.cc_state,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset = -8.00
  AND cr.cr_return_amount > 500
  AND wr.wr_fee BETWEEN 30 AND 100
  AND r.r_reason_desc LIKE '%purchase%'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND cr.cr_call_center_sk IN (SELECT key FROM intersect_keys)
GROUP BY cc.cc_state, r.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_catalog_return DESC
