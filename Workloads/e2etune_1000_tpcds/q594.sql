WITH city_metrics AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS total_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        ROUND(100.0 * SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) / COUNT(c.c_customer_sk), 2) AS pct_preferred_customers,
        (
            SELECT SUM(p_cost)
            FROM promotion p
            WHERE p.p_start_date_sk BETWEEN 2459580 AND 2459945
        ) AS total_promo_cost_2022,
        (
            SELECT COUNT(*)
            FROM call_center cc
            WHERE cc.cc_state = ca.ca_state
        ) AS call_center_count_in_state,
        (
            SELECT COUNT(*)
            FROM catalog_page cp
            WHERE cp.cp_type = 'A'
        ) AS catalog_page_type_A_count
    FROM
        customer c
    JOIN
        customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY')
        AND c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY
        ca.ca_city,
        ca.ca_state
    HAVING
        COUNT(c.c_customer_sk) >= 10
)
SELECT
    cm.*,
    ROW_NUMBER() OVER (ORDER BY cm.total_customers DESC) AS city_rank_by_customers
FROM
    city_metrics cm
ORDER BY
    cm.total_customers DESC
LIMIT 100
