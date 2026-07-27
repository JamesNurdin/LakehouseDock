WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_addr_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_sales_price) AS avg_sales,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN ss_list_price > 100 THEN ss_ext_sales_price ELSE 0 END) AS high_price_sales
    FROM store_sales
    WHERE ss_list_price BETWEEN 20 AND 150
      AND ss_ext_tax < 200
      AND ss_quantity > 1
      AND ss_coupon_amt = 0
    GROUP BY ss_sold_date_sk, ss_addr_sk, ss_customer_sk
)
SELECT
    d.d_year,
    ca.ca_state,
    c.c_birth_month,
    SUM(s.total_sales) AS sum_total_sales,
    AVG(s.avg_sales) AS avg_of_avg_sales,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MAX(s.high_price_sales) AS max_high_price_sales,
    CASE WHEN SUM(s.total_sales) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales_agg s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON s.ss_addr_sk = ca.ca_address_sk
JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_suite_number = 'Suite 390'
  AND c.c_birth_month IN (5, 6, 9)
  AND d.d_year = 1998
GROUP BY d.d_year, ca.ca_state, c.c_birth_month
ORDER BY sum_total_sales DESC
LIMIT 100
