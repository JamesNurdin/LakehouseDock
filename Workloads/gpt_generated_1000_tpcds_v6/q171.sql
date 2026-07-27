WITH
  store_monthly AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      SUM(ss.ss_net_profit) AS store_profit,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE EXISTS (
      SELECT 1
      FROM catalog_sales cs
      WHERE cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    )
    GROUP BY d.d_year, d.d_month_seq
  ),
  catalog_monthly AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      SUM(cs.cs_net_profit) AS catalog_profit,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY d.d_year, d.d_month_seq
  ),
  combined AS (
    SELECT d_year, month_seq, store_profit AS profit, 'store' AS source
    FROM store_monthly
    UNION ALL
    SELECT d_year, month_seq, catalog_profit AS profit, 'catalog' AS source
    FROM catalog_monthly
  )
SELECT
  c.d_year,
  c.month_seq,
  c.source,
  c.profit,
  SUM(c.profit) OVER (
    PARTITION BY c.d_year
    ORDER BY c.month_seq
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_profit
FROM combined c
ORDER BY c.d_year DESC, c.month_seq, c.source
LIMIT 100
