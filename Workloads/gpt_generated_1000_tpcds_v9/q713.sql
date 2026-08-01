WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN regexp_like(c.c_email_address, '@gmail\\.com$') THEN 'Gmail'
            WHEN regexp_like(c.c_email_address, '@yahoo\\.com$') THEN 'Yahoo'
            ELSE 'Other'
        END AS email_domain
    FROM
        customer c
    WHERE
        c.c_first_name LIKE 'M%'
        AND c.c_email_address LIKE '%@%'
),
sales_aggregates AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        ca.email_domain,
        substring(ca.c_last_name FROM 1 FOR 3) AS last_name_prefix,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN cs.cs_ext_discount_amt > 100 THEN cs.cs_ext_discount_amt ELSE 0 END) AS high_discount_total,
        MAX(e.email_user) AS sample_email_user
    FROM
        catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN filtered_customers ca ON cs.cs_bill_customer_sk = ca.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(ca.c_email_address, '^([^@]+)', 1) AS email_user
    ) AS e
    WHERE
        t.t_hour BETWEEN 8 AND 18
        AND sm.sm_type = 'AIR'
        AND regexp_like(ca.c_email_address, '@(gmail|yahoo)\\.com$')
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        ca.email_domain,
        substring(ca.c_last_name FROM 1 FOR 3)
)
SELECT
    sm_ship_mode_id,
    sm_type,
    email_domain,
    last_name_prefix,
    total_sales,
    total_profit,
    sales_cnt,
    high_discount_total,
    sample_email_user,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_profit DESC) AS profit_rank
FROM
    sales_aggregates
ORDER BY
    total_profit DESC,
    profit_rank
LIMIT 100
