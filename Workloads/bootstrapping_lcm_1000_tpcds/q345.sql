SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    sm.sm_type AS ship_mode_type,
    s.s_state AS store_state,
    s.s_market_desc AS store_market_desc,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    MAX(wp.wp_url) AS sample_url
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year >= 2000
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    s.s_state,
    s.s_market_desc
ORDER BY total_net_paid DESC
LIMIT 100
