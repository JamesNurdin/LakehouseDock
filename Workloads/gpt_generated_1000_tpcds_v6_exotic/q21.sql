WITH
  store_agg AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      ss.ss_sold_date_sk AS date_sk,
      SUM(ss.ss_net_paid) AS total_paid,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
    HAVING SUM(ss.ss_net_paid) > 1000
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      ws.ws_sold_date_sk AS date_sk,
      SUM(ws.ws_net_paid) AS total_paid,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_paid) > 1000
  ),
  combined AS (
    SELECT item_sk, date_sk, total_paid, total_profit FROM store_agg
    UNION ALL
    SELECT item_sk, date_sk, total_paid, total_profit FROM web_agg
  )
SELECT
  i.i_item_id,
  d.d_date,
  SUM(c.total_paid) AS agg_paid,
  SUM(c.total_profit) AS agg_profit
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
JOIN date_dim d ON c.date_sk = d.d_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = c.item_sk
          AND sr.sr_returned_date_sk = c.date_sk
      )
GROUP BY i.i_item_id, d.d_date
HAVING SUM(c.total_paid) > 1500
ORDER BY agg_paid DESC
LIMIT 100
