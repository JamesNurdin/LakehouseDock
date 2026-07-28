WITH sales_filtered AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ss.ss_net_profit,
        c.c_email_address,
        c.c_first_name,
        d.d_year,
        t.t_meal_time
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2000
      AND s.s_store_name LIKE '%Market%'
      AND c.c_first_name LIKE 'A%'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@.*\\.com$')
      AND t.t_meal_time = 'dinner'
)
SELECT
    s_store_id,
    s_store_name,
    CONCAT(s_store_name, ' - ', s_state) AS store_full_name,
    SUBSTRING(s_store_name, 1, 5) AS store_prefix,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT c_email_address) AS distinct_customers,
    regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain
FROM sales_filtered
GROUP BY
    s_store_id,
    s_store_name,
    CONCAT(s_store_name, ' - ', s_state),
    SUBSTRING(s_store_name, 1, 5),
    regexp_extract(c_email_address, '@(.+)$', 1)
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
