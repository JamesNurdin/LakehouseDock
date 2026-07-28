WITH
  sales_agg AS (
    SELECT
      d.d_date AS transaction_date,
      SUM(cs.cs_ext_sales_price) AS metric,
      'catalog_sales' AS source_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY d.d_date
  ),
  returns_agg AS (
    SELECT
      d.d_date AS transaction_date,
      SUM(sr.sr_net_loss) AS metric,
      'store_returns' AS source_type
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date
  ),
  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  ),
  ranked AS (
    SELECT DISTINCT
      transaction_date,
      metric,
      source_type,
      ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY metric DESC) AS rank
    FROM combined
  )
SELECT
  transaction_date,
  metric,
  source_type,
  rank
FROM ranked
WHERE rank <= 10
ORDER BY metric DESC
LIMIT 100
