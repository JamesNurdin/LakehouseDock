WITH filtered_stores AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        CONCAT(s.s_city, ', ', s.s_state) AS city_state,
        regexp_extract(s.s_store_name, '(\\w+)', 1) AS first_word
    FROM store s
    WHERE regexp_like(s.s_store_name, 'Outlet')
)
SELECT
    fs.s_store_id,
    d.d_year,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    CASE WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'High' ELSE 'Medium' END AS profit_category,
    fs.city_state,
    fs.first_word
FROM filtered_stores fs
JOIN store_sales ss ON ss.ss_store_sk = fs.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%.com'
GROUP BY
    fs.s_store_id,
    d.d_year,
    fs.city_state,
    fs.first_word
ORDER BY d.d_year DESC, total_net_profit DESC
LIMIT 100
