WITH joined AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        c.c_birth_year,
        ss.ss_net_paid_inc_tax,
        cs.cs_net_paid_inc_tax
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_salutation IN ('Mr.', 'Ms.')
        AND c.c_birth_year BETWEEN 1960 AND 1985
        AND ss.ss_net_paid_inc_tax > 100.00
        AND cs.cs_net_paid_inc_tax > 500.00
        AND cs.cs_bill_hdemo_sk IN (3708, 3797)
        AND EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
                AND ss2.ss_ext_tax > 20.00
        )
),
agg AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_salutation,
        c_birth_year,
        SUM(ss_net_paid_inc_tax) AS store_total,
        SUM(cs_net_paid_inc_tax) AS catalog_total,
        SUM(ss_net_paid_inc_tax) + SUM(cs_net_paid_inc_tax) AS combined_total
    FROM joined
    GROUP BY
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_salutation,
        c_birth_year
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_salutation,
    c_birth_year,
    store_total,
    catalog_total,
    combined_total,
    RANK() OVER (ORDER BY combined_total DESC) AS rank_by_combined_total,
    CASE
        WHEN combined_total > (SELECT AVG(combined_total) FROM agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS avg_comparison
FROM agg
ORDER BY rank_by_combined_total
LIMIT 100
