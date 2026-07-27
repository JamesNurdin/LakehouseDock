WITH catalog_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND cr.cr_return_tax >= 0
      AND cr.cr_fee >= 0
      AND cr.cr_return_ship_cost >= 0
    GROUP BY
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_call_center_sk
)
SELECT
    d.d_date,
    d.d_year,
    t.t_hour,
    r.r_reason_desc,
    CASE WHEN ca.total_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_level,
    SUM(sr.sr_return_amt) AS store_return_amount,
    ca.total_return_amount,
    (SUM(sr.sr_return_amt) + ca.total_return_amount) AS combined_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (SUM(sr.sr_return_amt) + ca.total_return_amount) DESC) AS rn
FROM catalog_agg ca
JOIN date_dim d ON ca.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON ca.cr_returned_time_sk = t.t_time_sk
JOIN reason r ON ca.cr_reason_sk = r.r_reason_sk
JOIN call_center cc ON ca.cr_call_center_sk = cc.cc_call_center_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2002
  AND t.t_shift = 'first'
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
  AND r.r_reason_desc LIKE '%purchase%'
  AND hd.hd_vehicle_count > 0
GROUP BY
    d.d_date,
    d.d_year,
    t.t_hour,
    r.r_reason_desc,
    ca.total_return_amount
HAVING SUM(sr.sr_return_amt) > 0
ORDER BY combined_return_amount DESC
LIMIT 100
