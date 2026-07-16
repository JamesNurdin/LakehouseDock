WITH filtered_customers AS (
    SELECT *
    FROM customer
    WHERE c_birth_month = 4
      AND c_preferred_cust_flag = 'Y'
),
store_customer_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
        AVG(2026 - c.c_birth_year) AS avg_age,
        COUNT(DISTINCT split_part(c.c_email_address, '@', 2)) AS distinct_email_domains
    FROM filtered_customers c
    JOIN store s
      ON s.s_state = substring(split_part(c.c_email_address, '@', 2), 1, 2)
    WHERE s.s_country = 'USA'
      AND s.s_gmt_offset BETWEEN -5 AND 0
    GROUP BY s.s_store_id, s.s_store_name, s.s_city
    HAVING COUNT(DISTINCT c.c_customer_id) > 5
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    customer_cnt,
    avg_age,
    distinct_email_domains,
    RANK() OVER (ORDER BY customer_cnt DESC) AS store_rank
FROM store_customer_agg
ORDER BY customer_cnt DESC
LIMIT 10
