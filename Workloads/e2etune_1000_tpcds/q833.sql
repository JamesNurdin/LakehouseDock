WITH cust_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_country,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt,
        MAX(c.c_last_review_date) AS latest_review_date
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state IS NOT NULL
      AND c.c_birth_year BETWEEN 1950 AND 2000
    GROUP BY ca.ca_state, ca.ca_country
    HAVING COUNT(*) > 100
)
SELECT
    ca_state,
    ca_country,
    cust_cnt,
    avg_birth_year,
    pref_cust_cnt,
    latest_review_date,
    RANK() OVER (ORDER BY cust_cnt DESC) AS state_rank
FROM cust_agg
ORDER BY cust_cnt DESC
LIMIT 20
