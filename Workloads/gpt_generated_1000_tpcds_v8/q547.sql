WITH full_sales_store AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_customer_sk,
       ss.ss_store_sk,
       ss.ss_ext_sales_price,
       ss.ss_coupon_amt,
       ss.ss_net_profit,
       s.s_market_id,
       s.s_market_desc,
       s.s_state,
       s.s_tax_percentage
   FROM store_sales ss
   FULL OUTER JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
),
customer_joined AS (
   SELECT
       f.*, 
       c.c_email_address,
       c.c_birth_year,
       c.c_preferred_cust_flag
   FROM full_sales_store f
   LEFT JOIN customer c
       ON f.ss_customer_sk = c.c_customer_sk
),
filtered AS (
   SELECT *
   FROM customer_joined
   WHERE
       s_market_id IN (1, 4, 5)                                 -- predicate 1
       AND ss_ext_sales_price > 1000                             -- predicate 2
       AND ss_coupon_amt < 500                                   -- predicate 3
       AND c_email_address LIKE '%@%'                           -- predicate 4
       AND c_birth_year BETWEEN 1960 AND 1990                    -- predicate 5
       AND s_state = 'CA'                                        -- predicate 6
       AND NOT EXISTS (
           SELECT 1
           FROM store_sales ss2
           WHERE ss2.ss_customer_sk = ss_customer_sk
             AND ss2.ss_ext_sales_price > 5000
       )
       AND ss_customer_sk IN (
           SELECT ss_customer_sk FROM store_sales WHERE ss_ext_discount_amt > 2000
           INTERSECT
           SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y'
       )
),
union_sales AS (
   SELECT ss_store_sk AS key_sk, SUM(ss_ext_sales_price) AS total_sales
   FROM store_sales
   GROUP BY ss_store_sk
   UNION
   SELECT ss_customer_sk AS key_sk, SUM(ss_ext_sales_price) AS total_sales
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   GROUP BY ss_customer_sk
),
final AS (
   SELECT
       f.ss_customer_sk,
       f.ss_store_sk,
       f.s_market_desc,
       f.ss_ext_sales_price,
       f.ss_net_profit,
       u.total_sales,
       CASE
           WHEN f.ss_net_profit > 1000 THEN 'High'
           WHEN f.ss_net_profit > 0    THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       ROW_NUMBER() OVER (PARTITION BY f.s_market_desc ORDER BY f.ss_ext_sales_price DESC) AS rn_market_sales,
       RANK() OVER (ORDER BY u.total_sales DESC) AS overall_sales_rank,
       AVG(f.ss_ext_sales_price) OVER (PARTITION BY f.s_state ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_sales
   FROM filtered f
   LEFT JOIN union_sales u
       ON (u.key_sk = f.ss_store_sk OR u.key_sk = f.ss_customer_sk)
)
SELECT
   ss_customer_sk,
   ss_store_sk,
   s_market_desc,
   ss_ext_sales_price,
   ss_net_profit,
   total_sales,
   profit_category,
   rn_market_sales,
   overall_sales_rank,
   moving_avg_sales
FROM final
WHERE rn_market_sales <= 5
ORDER BY overall_sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
