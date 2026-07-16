SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    s.s_store_name,
    wp.wp_type,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(cs.cs_ext_discount_amt) + SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    CASE
        WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High'
        ELSE 'Low'
    END AS catalog_sales_category,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_views,
    SUM(CASE WHEN wp.wp_type = 'category' THEN 1 ELSE 0 END) AS category_page_views
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
   AND ss.ss_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND wp.wp_type IS NOT NULL
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    wp.wp_type
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_catalog_net_paid DESC
LIMIT 100
