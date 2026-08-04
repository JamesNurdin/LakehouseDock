WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5)
),
matched_customers AS (
    SELECT c.c_customer_sk,
           concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_birth_year
    FROM customer c
    WHERE regexp_like(c.c_last_name, '^B[aeiou].*')
      AND c.c_preferred_cust_flag = 'Y'
),
customers_no_web AS (
    SELECT mc.c_customer_sk
    FROM matched_customers mc
    EXCEPT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
),
sales_filtered AS (
    SELECT ss.ss_store_sk,
           ss.ss_customer_sk,
           ss.ss_ext_sales_price,
           ss.ss_sold_time_sk
    FROM sampled_sales ss
    JOIN customers_no_web cnw ON ss.ss_customer_sk = cnw.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_ext_sales_price > 0
      AND td.t_hour BETWEEN 9 AND 17
),
store_agg AS (
    SELECT sf.ss_store_sk,
           sum(sf.ss_ext_sales_price) AS total_sales,
           count(*) AS sales_cnt
    FROM sales_filtered sf
    GROUP BY sf.ss_store_sk
),
store_details AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_city,
           s.s_state,
           s.s_geography_class
    FROM store s
    WHERE s.s_city LIKE '%York%'
)
SELECT
    sd.s_store_name,
    sd.s_city,
    sd.s_state,
    sd.s_geography_class,
    sa.total_sales,
    sa.sales_cnt,
    CASE
        WHEN sa.total_sales > (SELECT avg(total_sales) FROM store_agg) THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    substring(sd.s_store_name, 1, 10) AS store_name_prefix,
    concat('Store_', cast(sd.s_store_sk AS varchar)) AS store_key,
    (SELECT regexp_extract(wp.wp_url, '^(https?://[^/]+)')
     FROM web_page wp
     WHERE wp.wp_customer_sk IS NOT NULL
     LIMIT 1) AS sample_domain
FROM store_agg sa
JOIN store_details sd ON sa.ss_store_sk = sd.s_store_sk
ORDER BY sa.total_sales DESC
LIMIT 100
