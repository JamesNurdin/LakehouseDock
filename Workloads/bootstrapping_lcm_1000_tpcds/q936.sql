SELECT
    sold_dd.d_year AS sold_year,
    sold_dd.d_month_seq AS sold_month,
    ship_dd.d_year AS ship_year,
    sm.sm_carrier,
    s.s_market_desc,
    wp.wp_type,
    AVG(date_diff('day', sold_dd.d_date, wp_access_dd.d_date)) AS avg_days_between,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_quantity) AS total_quantity
FROM catalog_sales cs
JOIN date_dim sold_dd
  ON cs.cs_sold_date_sk = sold_dd.d_date_sk
JOIN date_dim ship_dd
  ON cs.cs_ship_date_sk = ship_dd.d_date_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
  ON s.s_closed_date_sk = sold_dd.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = sold_dd.d_date_sk
JOIN date_dim wp_access_dd
  ON wp.wp_access_date_sk = wp_access_dd.d_date_sk
WHERE sm.sm_carrier IN ('UPS', 'FedEx')
  AND s.s_state = 'CA'
  AND sold_dd.d_year = 2022
GROUP BY
    sold_dd.d_year,
    sold_dd.d_month_seq,
    ship_dd.d_year,
    sm.sm_carrier,
    s.s_market_desc,
    wp.wp_type
ORDER BY total_net_paid DESC
LIMIT 100
