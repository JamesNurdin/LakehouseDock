WITH unified AS (
    SELECT d.d_year AS year,
           cd.cd_gender AS gender,
           SUM(cs.cs_net_paid) AS amount,
           'sales' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender

    UNION ALL

    SELECT d.d_year AS year,
           cd.cd_gender AS gender,
           SUM(sr.sr_return_amt) AS amount,
           'returns' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
)
SELECT year,
       gender,
       amount,
       CASE WHEN src = 'sales' THEN amount ELSE -amount END AS signed_amount
FROM unified
ORDER BY year, gender
LIMIT 100
