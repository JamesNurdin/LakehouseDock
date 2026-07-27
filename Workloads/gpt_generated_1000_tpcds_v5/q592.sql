WITH avg_fee AS (
    SELECT AVG(cr_fee) AS overall_avg_fee
    FROM tpcds.catalog_returns
)
SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    sm.sm_contract,
    t.t_hour,
    s.s_store_name,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    MIN(cr.cr_return_quantity) AS min_qty,
    MAX(cr.cr_return_quantity) AS max_qty,
    (AVG(cr.cr_fee) / avg_fee.overall_avg_fee) AS fee_to_overall_ratio
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.store s
    ON s.s_closed_date_sk = d.d_date_sk
CROSS JOIN avg_fee
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND sm.sm_type = 'OVERNIGHT'
  AND sm.sm_contract = 'YvxVaJI10'
  AND t.t_hour BETWEEN 9 AND 17
  AND cr.cr_fee > 20.00
  AND cr.cr_return_quantity <= 5
  AND EXISTS (
        SELECT 1
        FROM tpcds.store s2
        WHERE s2.s_state = 'CA' AND s2.s_store_sk = s.s_store_sk
    )
GROUP BY d.d_year,
         d.d_month_seq,
         sm.sm_type,
         sm.sm_contract,
         t.t_hour,
         s.s_store_name,
         avg_fee.overall_avg_fee
HAVING SUM(cr.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
