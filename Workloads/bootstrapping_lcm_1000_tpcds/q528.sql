SELECT
    d_sold.d_date AS sale_date,
    d_sold.d_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_date AS ship_date,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    t.t_hour,
    t.t_minute,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT s_closed.s_store_sk) AS closed_stores_on_sale_date,
    COUNT(DISTINCT s_ship_closed.s_store_sk) AS closed_stores_on_ship_date,
    COUNT(DISTINCT wp_c.wp_web_page_sk) AS pages_created_on_sale_date,
    COUNT(DISTINCT wp_a.wp_web_page_sk) AS pages_accessed_on_sale_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN store s_closed
    ON s_closed.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN store s_ship_closed
    ON s_ship_closed.s_closed_date_sk = d_ship.d_date_sk
LEFT JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_date,
    d_ship.d_year,
    d_ship.d_month_seq,
    t.t_hour,
    t.t_minute
ORDER BY total_net_paid DESC
LIMIT 100
