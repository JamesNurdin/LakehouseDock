SELECT
    ds_sold.d_year AS sold_year,
    ds_sold.d_quarter_name AS sold_quarter,
    ds_sold.d_month_seq AS sold_month,
    t.t_hour AS hour_of_day,
    t.t_meal_time,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(cs.cs_net_paid) / NULLIF(COUNT(DISTINCT cs.cs_order_number), 0) AS avg_paid_per_order,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    MAX(wp.wp_image_count) AS max_image_count,
    MIN(ds_wp_creation.d_date) AS earliest_page_creation,
    MAX(ds_wp_access.d_date) AS latest_page_access
FROM catalog_sales cs
JOIN date_dim ds_sold
    ON cs.cs_sold_date_sk = ds_sold.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN date_dim ds_ship
    ON cs.cs_ship_date_sk = ds_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ds_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = ds_ship.d_date_sk
JOIN date_dim ds_wp_creation
    ON wp.wp_creation_date_sk = ds_wp_creation.d_date_sk
JOIN date_dim ds_wp_access
    ON wp.wp_access_date_sk = ds_wp_access.d_date_sk
WHERE ds_sold.d_year BETWEEN 2020 AND 2022
  AND t.t_meal_time = 'Dinner'
  AND s.s_state = 'CA'
GROUP BY
    ds_sold.d_year,
    ds_sold.d_quarter_name,
    ds_sold.d_month_seq,
    t.t_hour,
    t.t_meal_time,
    s.s_store_name,
    s.s_state
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
