SELECT
    t.state,
    t.country,
    t.total_customers,
    t.distinct_customers,
    t.avg_birth_year,
    t.pct_preferred,
    t.median_birth_year,
    ROW_NUMBER() OVER (ORDER BY t.total_customers DESC) AS rank_by_customers
FROM (
    SELECT
        ca.ca_state AS state,
        ca.ca_country AS country,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_preferred,
        approx_percentile(c.c_birth_year, 0.5) AS median_birth_year
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country IN ('CHILE', 'MEXICO', 'FIJI')
      AND c.c_birth_year BETWEEN 1950 AND 2000
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
    GROUP BY ca.ca_state, ca.ca_country
    HAVING COUNT(*) > 100
) t
ORDER BY t.total_customers DESC, t.avg_birth_year ASC
LIMIT 20
