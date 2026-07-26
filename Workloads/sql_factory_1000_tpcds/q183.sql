WITH store_customer_stats AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(2023 - c.c_birth_year - CASE WHEN c.c_birth_month > 6 THEN 1 ELSE 0 END) AS avg_customer_age,
        SUM(CASE WHEN (2023 - c.c_birth_year) < 30 THEN ss.ss_net_profit ELSE 0 END) AS profit_young,
        SUM(CASE WHEN (2023 - c.c_birth_year) BETWEEN 30 AND 50 THEN ss.ss_net_profit ELSE 0 END) AS profit_mid,
        SUM(CASE WHEN (2023 - c.c_birth_year) > 50 THEN ss.ss_net_profit ELSE 0 END) AS profit_senior,
        COUNT(DISTINCT wp.wp_web_page_sk) AS total_web_pages
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_number_employees
)
SELECT
    s_store_sk,
    s_store_name,
    total_net_profit,
    total_net_paid,
    distinct_customers,
    avg_customer_age,
    profit_young,
    profit_mid,
    profit_senior,
    total_web_pages,
    CASE
        WHEN total_net_profit > 200000 THEN 'Platinum'
        WHEN total_net_profit > 100000 THEN 'Gold'
        WHEN total_net_profit > 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY avg_customer_age) AS age_density_rank
FROM store_customer_stats
ORDER BY profit_rank
LIMIT 20
