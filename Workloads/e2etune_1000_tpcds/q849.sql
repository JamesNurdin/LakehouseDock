SELECT
    s.s_store_name,
    i.i_category,
    DATE_TRUNC('month', date_parse(CAST(ss.ss_sold_date_sk AS VARCHAR), '%Y%m%d')) AS sales_month,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COALESCE(SUM(wp.wp_image_count), 0) AS total_images_viewed
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
WHERE ss.ss_sold_date_sk BETWEEN 19980101 AND 19981231
  AND s.s_state = 'CA'
  AND i.i_brand = 'BrandX'
GROUP BY
    s.s_store_name,
    i.i_category,
    DATE_TRUNC('month', date_parse(CAST(ss.ss_sold_date_sk AS VARCHAR), '%Y%m%d'))
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 50
