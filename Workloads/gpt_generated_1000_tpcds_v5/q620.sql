WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM store_sales
    WHERE ss_ext_discount_amt > 0
      AND ss_quantity >= 1
      AND ss_sales_price > 0
      AND ss_wholesale_cost > 0
      AND ss_net_paid > 0
      AND ss_net_profit > 0
    GROUP BY ss_sold_date_sk
)
SELECT
    d1.d_year,
    d1.d_quarter_name,
    wp.wp_type,
    SUM(ss_agg.total_sales) AS sum_sales,
    AVG(ss_agg.total_discount) AS avg_discount,
    COUNT(*) AS page_views,
    MAX(wp.wp_link_count) AS max_links,
    MIN(wp.wp_char_count) AS min_char_count
FROM ss_agg
JOIN date_dim d1
    ON ss_agg.ss_sold_date_sk = d1.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d1.d_date_sk
JOIN date_dim d2
    ON wp.wp_access_date_sk = d2.d_date_sk
WHERE d1.d_year = 2001
  AND d1.d_holiday = 'N'
  AND d1.d_qoy = 2
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_link_count >= 5
  AND wp.wp_char_count BETWEEN 500 AND 5000
GROUP BY d1.d_year, d1.d_quarter_name, wp.wp_type
HAVING SUM(ss_agg.total_sales) > 10000
   AND COUNT(*) >= 10
ORDER BY sum_sales DESC
LIMIT 100
