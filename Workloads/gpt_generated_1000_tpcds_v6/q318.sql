WITH cust_demo_addr AS (
    SELECT
        c.c_customer_sk,
        c.c_last_review_date,
        c.c_email_address,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ca.ca_country,
        ca.ca_address_id
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ca_country,
    cust_cnt,
    vehicle_flag_count
FROM (
    SELECT
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS cust_cnt,
        SUM(CASE WHEN hd_vehicle_count >= 3 THEN 1 ELSE 0 END) AS vehicle_flag_count
    FROM cust_demo_addr
    WHERE hd_vehicle_count >= 2
      AND ca_country = 'United States'
      AND c_last_review_date > 2452500
    GROUP BY ca_country

    UNION ALL

    SELECT
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS cust_cnt,
        SUM(CASE WHEN hd_vehicle_count = 0 THEN 1 ELSE 0 END) AS vehicle_flag_count
    FROM cust_demo_addr
    WHERE hd_vehicle_count = 0
      AND ca_country = 'United States'
      AND c_last_review_date <= 2452500
    GROUP BY ca_country
) AS combined
ORDER BY ca_country, cust_cnt DESC
