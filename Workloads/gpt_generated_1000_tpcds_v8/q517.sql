WITH
  intersect_dates AS (
    SELECT ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),
  except_dates AS (
    SELECT ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    EXCEPT
    SELECT ws.ws_sold_date_sk
    FROM web_sales ws
  ),
  full_sales AS (
    SELECT
      COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS date_sk,
      ss.ss_store_sk,
      ws.ws_ship_mode_sk,
      ss.ss_net_profit,
      ws.ws_net_profit
    FROM store_sales ss
    FULL OUTER JOIN web_sales ws
      ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
     AND ss.ss_item_sk = ws.ws_item_sk
  ),
  filtered_sales AS (
    SELECT
      d.d_date,
      fs.ss_store_sk,
      fs.ws_ship_mode_sk,
      fs.ss_net_profit,
      fs.ws_net_profit,
      (SELECT SUM(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_sold_date_sk = d.d_date_sk) AS total_store_profit,
      (SELECT SUM(ws2.ws_net_profit)
         FROM web_sales ws2
         WHERE ws2.ws_sold_date_sk = d.d_date_sk) AS total_web_profit,
      CASE WHEN EXISTS (SELECT 1 FROM intersect_dates i WHERE i.date_sk = fs.date_sk)
           THEN 'Y' ELSE 'N' END AS intersect_flag,
      CASE WHEN NOT EXISTS (SELECT 1 FROM except_dates e WHERE e.date_sk = fs.date_sk)
           THEN 'Y' ELSE 'N' END AS except_flag
    FROM full_sales fs
    JOIN date_dim d ON fs.date_sk = d.d_date_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_returned_date_sk = d.d_date_sk
    )
  )
SELECT
  d_date,
  ss_store_sk,
  ws_ship_mode_sk,
  ss_net_profit,
  ws_net_profit,
  total_store_profit,
  total_web_profit,
  intersect_flag,
  except_flag
FROM filtered_sales
UNION ALL
SELECT
  d.d_date,
  NULL AS ss_store_sk,
  NULL AS ws_ship_mode_sk,
  NULL AS ss_net_profit,
  NULL AS ws_net_profit,
  NULL AS total_store_profit,
  NULL AS total_web_profit,
  'N' AS intersect_flag,
  'N' AS except_flag
FROM date_dim d
WHERE d.d_year BETWEEN 1999 AND 2000
ORDER BY d_date DESC, ss_store_sk
LIMIT 100
