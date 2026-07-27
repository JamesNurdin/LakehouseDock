WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2020
)
SELECT
    'call_center' AS source,
    cc.cc_name AS name,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN recent_dates rd
  ON cr.cr_returned_date_sk = rd.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd
    WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
      AND hd.hd_vehicle_count > 0
)
GROUP BY cc.cc_name

UNION ALL

SELECT
    'promotion' AS source,
    p.p_promo_name AS name,
    SUM(p.p_cost) AS total_return_amount
FROM promotion p
JOIN recent_dates rd
  ON p.p_start_date_sk = rd.d_date_sk
GROUP BY p.p_promo_name

ORDER BY total_return_amount DESC, source, name
LIMIT 100
