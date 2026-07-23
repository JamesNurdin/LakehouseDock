WITH state_agg AS (
    SELECT
        ca.ca_state,
        CASE
            WHEN c.c_birth_country IN ('KOREA', 'CYPRUS') THEN 'Asia/Cyprus'
            WHEN c.c_birth_country IN ('HUNGARY', 'KAZAKHSTAN') THEN 'Europe/Asia'
            ELSE 'Other'
        END AS region_category,
        COUNT(*) AS customer_cnt,
        AVG(c.c_current_hdemo_sk) AS avg_hdemo_sk,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_cnt
    FROM
        tpcds.customer AS c
        JOIN tpcds.customer_address AS ca
            ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_country IN ('KOREA', 'CYPRUS', 'HUNGARY', 'KAZAKHSTAN', 'NAURU')
        AND c.c_current_hdemo_sk BETWEEN 80 AND 6500
        AND ca.ca_gmt_offset BETWEEN -10.00 AND -5.00
        AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
        AND c.c_preferred_cust_flag IN ('Y', 'N')
    GROUP BY
        ca.ca_state,
        CASE
            WHEN c.c_birth_country IN ('KOREA', 'CYPRUS') THEN 'Asia/Cyprus'
            WHEN c.c_birth_country IN ('HUNGARY', 'KAZAKHSTAN') THEN 'Europe/Asia'
            ELSE 'Other'
        END
),
region_agg AS (
    SELECT
        region_category,
        SUM(customer_cnt) AS region_total_customers,
        AVG(avg_hdemo_sk) AS region_avg_hdemo,
        SUM(preferred_cnt) AS region_preferred_customers
    FROM
        state_agg
    GROUP BY
        region_category
)
SELECT
    sa.ca_state,
    sa.region_category,
    sa.customer_cnt,
    sa.avg_hdemo_sk,
    sa.preferred_cnt,
    ra.region_total_customers,
    ra.region_avg_hdemo,
    ROW_NUMBER() OVER (PARTITION BY sa.region_category ORDER BY sa.customer_cnt DESC) AS state_rank_in_region,
    RANK() OVER (ORDER BY ra.region_total_customers DESC) AS region_rank_by_total_customers
FROM
    state_agg AS sa
    JOIN region_agg AS ra ON sa.region_category = ra.region_category
WHERE
    sa.customer_cnt >= 10
    AND ra.region_total_customers > 20
ORDER BY
    region_rank_by_total_customers,
    state_rank_in_region
LIMIT 100
