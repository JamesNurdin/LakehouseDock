WITH
  ss_agg AS (
    SELECT d.d_date AS day,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
  ),
  cs_agg AS (
    SELECT d.d_date AS day,
           SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
  ),
  full_profit AS (
    SELECT
      COALESCE(ss.day, cs.day) AS day,
      COALESCE(ss.store_profit, 0) AS store_profit,
      COALESCE(cs.catalog_profit, 0) AS catalog_profit,
      0.0 AS net_loss,
      CASE
        WHEN COALESCE(ss.store_profit, 0) > COALESCE(cs.catalog_profit, 0) THEN 'Store Higher'
        WHEN COALESCE(cs.catalog_profit, 0) > COALESCE(ss.store_profit, 0) THEN 'Catalog Higher'
        ELSE 'Equal'
      END AS note
    FROM ss_agg ss
    FULL OUTER JOIN cs_agg cs ON ss.day = cs.day
  ),
  web_loss AS (
    SELECT
      d.d_date AS day,
      0.0 AS store_profit,
      0.0 AS catalog_profit,
      SUM(wr.wr_net_loss) AS net_loss,
      CASE
        WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High Loss'
        ELSE 'Low/Medium Loss'
      END AS note
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
  )
SELECT day,
       store_profit,
       catalog_profit,
       net_loss,
       note
FROM full_profit
UNION ALL
SELECT day,
       store_profit,
       catalog_profit,
       net_loss,
       note
FROM web_loss
ORDER BY day DESC, note
LIMIT 100
