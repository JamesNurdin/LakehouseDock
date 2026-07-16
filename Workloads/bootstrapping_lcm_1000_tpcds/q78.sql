SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_page_number,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ship.d_date AS store_closed_date,
    d_sales.d_date AS sales_date,
    d_ship.d_date AS ship_date,
    d_cp_start.d_date AS page_start_date,
    d_cp_end.d_date AS page_end_date,
    d_web_access.d_date AS wp_access_date,
    wp.wp_url,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    CASE WHEN d_sales.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS sales_day_category,
    DATE_DIFF('day', d_cp_start.d_date, d_sales.d_date) AS days_between_page_start_and_sales
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_web_access
    ON wp.wp_access_date_sk = d_web_access.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_page_number,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ship.d_date,
    d_sales.d_date,
    d_cp_start.d_date,
    d_cp_end.d_date,
    d_web_access.d_date,
    wp.wp_url,
    wp.wp_type,
    d_sales.d_weekend
ORDER BY total_net_paid DESC
LIMIT 100
