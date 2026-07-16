SELECT
    d.d_year,
    d.d_month_seq,
    d.d_date,
    sm.sm_type,
    sm.sm_carrier,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_amount) - SUM(cr.cr_fee) AS net_return_excluding_fee,
    CASE
        WHEN SUM(cr.cr_return_amount) > 50000 THEN 'HIGH'
        WHEN SUM(cr.cr_return_amount) > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND wp.wp_type = 'product'
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_date,
    sm.sm_type,
    sm.sm_carrier,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url
ORDER BY total_return_amount DESC
LIMIT 100
