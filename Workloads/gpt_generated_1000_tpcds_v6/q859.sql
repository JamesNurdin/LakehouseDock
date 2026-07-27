WITH sales_agg AS (
    SELECT
        c.c_birth_country AS country,
        SUM(cs.cs_net_paid_inc_ship) AS total_amount,
        'sales' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY c.c_birth_country
),
returns_agg AS (
    SELECT
        c.c_birth_country AS country,
        SUM(sr.sr_return_amt) AS total_amount,
        'returns' AS source
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt > 100
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY c.c_birth_country
)
SELECT country, total_amount, source
FROM sales_agg
UNION ALL
SELECT country, total_amount, source
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
