WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        CASE
            WHEN c.c_birth_year < 1950 THEN 'Pre-1950'
            WHEN c.c_birth_year BETWEEN 1950 AND 1970 THEN '1950-1970'
            ELSE 'Post-1970'
        END AS birth_cohort
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_coupon_amt > 1000
      AND cs.cs_ext_list_price BETWEEN 1000 AND 20000
      AND cs.cs_wholesale_cost < 100
      AND c.c_birth_year IS NOT NULL
      AND c.c_first_sales_date_sk >= 2450000
    GROUP BY
        c.c_customer_sk,
        c.c_birth_year,
        CASE
            WHEN c.c_birth_year < 1950 THEN 'Pre-1950'
            WHEN c.c_birth_year BETWEEN 1950 AND 1970 THEN '1950-1970'
            ELSE 'Post-1970'
        END
)
SELECT
    cs.birth_cohort,
    COUNT(*) AS customers_in_cohort,
    AVG(cs.total_profit) AS avg_profit_per_customer,
    SUM(cs.total_discount) AS cohort_total_discount,
    (
        SELECT MAX(inner_cs.total_profit)
        FROM customer_sales inner_cs
        WHERE inner_cs.order_cnt > 5
    ) AS max_profit_high_volume
FROM customer_sales cs
WHERE cs.order_cnt >= 3
  AND cs.total_profit > 0
  AND cs.birth_cohort <> 'Pre-1950'
  AND cs.total_discount < (
        SELECT AVG(cs2.total_discount)
        FROM customer_sales cs2
    )
GROUP BY cs.birth_cohort
HAVING AVG(cs.total_profit) > 500
ORDER BY avg_profit_per_customer DESC
LIMIT 100
