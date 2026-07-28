WITH sales_agg AS (
    SELECT d.d_year AS year,
           SUM(ss.ss_net_profit) AS amount,
           'store_sales' AS source
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sales_price > 5
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
returns_agg AS (
    SELECT d.d_year AS year,
           SUM(sr.sr_net_loss) * -1 AS amount,
           'store_returns' AS source
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_quantity > 0
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY year DESC, source
LIMIT 100
