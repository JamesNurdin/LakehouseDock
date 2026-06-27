WITH
  store AS (
    SELECT
      i.i_category,
      td.t_hour,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY i.i_category, td.t_hour
  ),
  catalog AS (
    SELECT
      i.i_category,
      td.t_hour,
      SUM(cs.cs_net_profit) AS catalog_net_profit,
      SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY i.i_category, td.t_hour
  ),
  web AS (
    SELECT
      i.i_category,
      td.t_hour,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY i.i_category, td.t_hour
  )
SELECT
  COALESCE(s.i_category, c.i_category, w.i_category) AS category,
  COALESCE(s.t_hour, c.t_hour, w.t_hour) AS hour_of_day,
  s.store_net_profit,
  s.store_net_loss,
  c.catalog_net_profit,
  c.catalog_net_loss,
  w.web_net_profit,
  w.web_net_loss
FROM store s
FULL OUTER JOIN catalog c
  ON s.i_category = c.i_category AND s.t_hour = c.t_hour
FULL OUTER JOIN web w
  ON COALESCE(s.i_category, c.i_category) = w.i_category
 AND COALESCE(s.t_hour, c.t_hour) = w.t_hour
ORDER BY category, hour_of_day
