SELECT
    s.s_state,
    sold_date.d_date AS sold_date,
    access_date.d_date AS access_date,
    date_diff('day', sold_date.d_date, access_date.d_date) AS days_between,
    td.t_meal_time,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    COUNT(DISTINCT wp.wp_web_page_sk) AS created_web_pages,
    COUNT(DISTINCT CASE WHEN access_date.d_date > sold_date.d_date THEN wp.wp_web_page_sk END) AS later_accessed_web_pages
FROM catalog_sales cs
JOIN date_dim sold_date
    ON cs.cs_sold_date_sk = sold_date.d_date_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN date_dim ship_date
    ON cs.cs_ship_date_sk = ship_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ship_date.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = sold_date.d_date_sk
JOIN date_dim access_date
    ON wp.wp_access_date_sk = access_date.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY
    s.s_state,
    sold_date.d_date,
    access_date.d_date,
    td.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
