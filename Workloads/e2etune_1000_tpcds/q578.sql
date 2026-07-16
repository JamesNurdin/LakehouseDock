WITH state_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_country,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_count,
        AVG(c.c_birth_year) AS avg_birth_year,
        AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
        MIN(c.c_first_sales_date_sk) AS min_sales_date,
        MAX(c.c_last_review_date) AS max_review_date
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_month IN (2, 4, 10, 11, 12)
        AND ca.ca_zip LIKE '9%'
    GROUP BY ca.ca_state, ca.ca_country
    HAVING COUNT(*) >= 5
)
SELECT
    ca_state,
    ca_country,
    customer_count,
    preferred_count,
    avg_birth_year,
    avg_gmt_offset,
    min_sales_date,
    max_review_date,
    RANK() OVER (ORDER BY customer_count DESC) AS state_rank
FROM state_agg
ORDER BY customer_count DESC
LIMIT 50
