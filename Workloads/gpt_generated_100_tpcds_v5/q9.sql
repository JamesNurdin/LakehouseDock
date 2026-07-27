WITH sales_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        c.c_customer_id,
        c.c_first_name,
        s.s_manager,
        s.s_division_id,
        s.s_store_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_manager = 'Matt Frederick'
      AND s.s_division_id = 1
      AND c.c_first_name = 'Timothy'
      AND ss.ss_ext_sales_price > 1000
)
SELECT
    s_manager,
    s_division_id,
    s_store_name,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_ext_sales_price) AS min_sales,
    MAX(ss_ext_sales_price) AS max_sales
FROM sales_data
GROUP BY s_manager, s_division_id, s_store_name
ORDER BY total_sales DESC
LIMIT 100
