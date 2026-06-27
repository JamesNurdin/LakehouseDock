WITH
  store AS (
    SELECT
      i.i_category AS category,
      i.i_brand    AS brand,
      SUM(ss.ss_net_profit)                         AS store_net_profit,
      SUM(COALESCE(sr.sr_net_loss, 0))              AS store_net_loss
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk       = sr.sr_item_sk
    GROUP BY i.i_category, i.i_brand
  ),
  catalog AS (
    SELECT
      i.i_category AS category,
      i.i_brand    AS brand,
      SUM(cs.cs_net_profit)                         AS catalog_net_profit,
      SUM(COALESCE(cr.cr_net_loss, 0))              AS catalog_net_loss
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk      = cr.cr_item_sk
    GROUP BY i.i_category, i.i_brand
  ),
  web AS (
    SELECT
      i.i_category AS category,
      i.i_brand    AS brand,
      SUM(ws.ws_net_profit)                         AS web_net_profit,
      SUM(COALESCE(wr.wr_net_loss, 0))              AS web_net_loss
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk      = wr.wr_item_sk
    GROUP BY i.i_category, i.i_brand
  )
SELECT
  COALESCE(s.category, c.category, w.category) AS category,
  COALESCE(s.brand,    c.brand,    w.brand)    AS brand,
  COALESCE(s.store_net_profit, 0)   + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)
  - (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0))
  AS total_net_profit
FROM store   s
FULL OUTER JOIN catalog c
  ON s.category = c.category AND s.brand = c.brand
FULL OUTER JOIN web w
  ON COALESCE(s.category, c.category) = w.category
 AND COALESCE(s.brand,    c.brand)    = w.brand
ORDER BY total_net_profit DESC
LIMIT 10
