WITH store_profit AS (
  SELECT s.s_state AS state,
         SUM(ss.ss_net_profit) AS profit,
         CAST(0 AS DECIMAL(15,2)) AS loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
  GROUP BY s.s_state
), store_loss AS (
  SELECT s.s_state AS state,
         CAST(0 AS DECIMAL(15,2)) AS profit,
         SUM(sr.sr_net_loss) AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
  GROUP BY s.s_state
), web_profit AS (
  SELECT ca.ca_state AS state,
         SUM(ws.ws_net_profit) AS profit,
         CAST(0 AS DECIMAL(15,2)) AS loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2002
  GROUP BY ca.ca_state
), web_loss AS (
  SELECT ca.ca_state AS state,
         CAST(0 AS DECIMAL(15,2)) AS profit,
         SUM(wr.wr_net_loss) AS loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2002
  GROUP BY ca.ca_state
), combined AS (
  SELECT state,
         SUM(profit) AS profit,
         SUM(loss) AS loss
  FROM (
    SELECT * FROM store_profit
    UNION ALL
    SELECT * FROM store_loss
    UNION ALL
    SELECT * FROM web_profit
    UNION ALL
    SELECT * FROM web_loss
  ) t
  GROUP BY state
)
SELECT state,
       profit - loss AS net_profit
FROM combined
ORDER BY net_profit DESC
LIMIT 10
