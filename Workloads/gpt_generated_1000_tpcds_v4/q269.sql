WITH filtered_returns AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 50
)
SELECT
    r.r_reason_desc,
    td.t_hour,
    td.t_minute,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt
FROM filtered_returns fr
JOIN time_dim td ON fr.cr_returned_time_sk = td.t_time_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
JOIN customer c ON fr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE td.t_hour IN (9, 12, 14)
  AND td.t_minute >= 10
  AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
  AND c.c_preferred_cust_flag = 'Y'
  AND hd.hd_vehicle_count >= 2
GROUP BY r.r_reason_desc, td.t_hour, td.t_minute
ORDER BY total_return_amount DESC
LIMIT 100
