SELECT
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_day_name AS ship_day_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS num_sales,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_margin,
    MIN(d_creation.d_date) AS earliest_page_creation,
    MAX(d_access.d_date) AS latest_page_access
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_store
    ON true
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_creation
    ON true
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_day_name
ORDER BY total_net_paid DESC
LIMIT 100
