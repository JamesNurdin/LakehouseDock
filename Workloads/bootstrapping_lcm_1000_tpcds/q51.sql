SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sales_year,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_count,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date
FROM catalog_sales cs
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
INNER JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
INNER JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
INNER JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
INNER JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2000
  AND s.s_state = 'CA'
  AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_cc_open.d_date,
    d_cc_closed.d_date
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 50
