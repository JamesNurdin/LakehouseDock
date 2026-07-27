SELECT
    sm.sm_carrier,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH_LOSS' ELSE 'LOW_LOSS' END AS loss_category,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
WHERE cr.cr_return_amount > 150.00
  AND cr.cr_return_ship_cost BETWEEN 20.00 AND 200.00
  AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        WHERE ws.web_open_date_sk = d.d_date_sk
          AND ws.web_country = 'United States'
    )
GROUP BY sm.sm_carrier, d.d_year
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
