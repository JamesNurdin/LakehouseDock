WITH cust_sales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_profit) > 5000
),
country_agg AS (
    SELECT
        c.c_birth_country,
        c.c_birth_year,
        COUNT(*) AS num_customers,
        SUM(cs.total_profit) AS country_total_profit,
        AVG(cs.avg_discount) AS country_avg_discount,
        SUM(cs.total_quantity) AS country_total_quantity
    FROM cust_sales cs
    JOIN customer c
        ON cs.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_month IN (4, 6, 9, 12)
    GROUP BY c.c_birth_country, c.c_birth_year
    HAVING COUNT(*) >= 5
)
SELECT
    c_birth_country,
    c_birth_year,
    num_customers,
    country_total_profit,
    country_avg_discount,
    country_total_quantity,
    RANK() OVER (ORDER BY country_total_profit DESC) AS profit_rank
FROM country_agg
ORDER BY country_total_profit DESC
LIMIT 100
