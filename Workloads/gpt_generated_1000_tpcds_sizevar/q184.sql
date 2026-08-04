WITH cs_agg AS (
    SELECT
        d.d_date AS sale_date,
        'catalog_sales' AS source,
        SUM(cs.cs_net_paid) AS total_amount,
        (SELECT SUM(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_day > 20
      AND d.d_holiday = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = cs.cs_bill_customer_sk
            AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY d.d_date
),
sr_agg AS (
    SELECT
        d.d_date AS sale_date,
        'store_returns' AS source,
        SUM(sr.sr_return_amt) AS total_amount,
        (SELECT SUM(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_total_net_paid
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_day <= 20
      AND d.d_holiday = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_bill_customer_sk = sr.sr_customer_sk
            AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
      )
    GROUP BY d.d_date
)
SELECT sale_date, source, total_amount, overall_total_net_paid
FROM cs_agg
UNION ALL
SELECT sale_date, source, total_amount, overall_total_net_paid
FROM sr_agg
ORDER BY sale_date, source
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
