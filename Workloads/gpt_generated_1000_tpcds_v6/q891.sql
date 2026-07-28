WITH promo_filtered AS (
    SELECT p_promo_sk,
           p_promo_name
    FROM promotion
    WHERE regexp_like(p_promo_name, '(?i)discount')
),
sales_data AS (
    SELECT ss.ss_store_sk,
           ss.ss_customer_sk,
           ss.ss_net_paid,
           s.s_store_name,
           s.s_city,
           s.s_state,
           concat(s.s_city, ', ', s.s_state) AS store_location,
           substring(s.s_store_name, 1, 10) AS store_name_prefix,
           p.p_promo_name,
           t.t_meal_time
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promo_filtered p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_store_name LIKE '%Online%'
      AND t.t_meal_time = 'lunch'
)
SELECT
    store_location,
    store_name_prefix,
    p_promo_name,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers
FROM sales_data
GROUP BY
    store_location,
    store_name_prefix,
    p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
