WITH
  store_data AS (
    SELECT
      'store' AS channel,
      d.d_year AS year,
      SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
    GROUP BY d.d_year
    HAVING SUM(ss.ss_net_paid) > 50000
  ),
  web_data AS (
    SELECT
      'web' AS channel,
      d.d_year AS year,
      SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
    GROUP BY d.d_year
    HAVING SUM(ws.ws_net_paid) > 50000
  ),
  combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
  )
SELECT DISTINCT
  c.channel,
  c.year,
  c.total_net_paid,
  CASE
    WHEN c.total_net_paid >= (
      SELECT AVG(total_net_paid)
      FROM (
        SELECT total_net_paid FROM store_data
        UNION ALL
        SELECT total_net_paid FROM web_data
      ) avg_tbl
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS performance
FROM combined c
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss2
  JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = c.year
  LIMIT 1
)
ORDER BY c.total_net_paid DESC
LIMIT 100
