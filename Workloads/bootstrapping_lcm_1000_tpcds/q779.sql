SELECT
    cp.cp_department,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    COUNT(*) AS sales_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    CASE
        WHEN SUM(cs.cs_net_paid) >= 100000 THEN 'Platinum'
        WHEN SUM(cs.cs_net_paid) >= 50000 THEN 'Gold'
        WHEN SUM(cs.cs_net_paid) >= 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS revenue_tier
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND d_wp_access.d_dow IN (1,2,3,4,5)
GROUP BY
    cp.cp_department,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
