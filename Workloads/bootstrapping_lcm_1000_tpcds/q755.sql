SELECT
    d_sold.d_year,
    s.s_store_name,
    s.s_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
    COUNT(DISTINCT CASE WHEN wp.wp_access_date_sk = d_access.d_date_sk THEN wp.wp_web_page_id END) AS pages_accessed,
    SUM(ss.ss_ext_sales_price) / NULLIF(COUNT(DISTINCT ss.ss_ticket_number), 0) AS avg_sales_per_ticket,
    MAX(ss.ss_net_profit) AS max_net_profit,
    MIN(ss.ss_net_profit) AS min_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY d_sold.d_date) AS rn_store_date,
    MAX(d_closed.d_date) AS store_closed_date,
    MAX(d_access.d_year) AS access_year
FROM date_dim d_sold
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
  AND i.inv_quantity_on_hand > 0
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    s.s_city,
    d_sold.d_date,
    s.s_store_sk
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
