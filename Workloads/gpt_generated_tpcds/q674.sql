WITH
  sales_store AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  sales_catalog AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  sales_web AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  sales_total AS (
    SELECT i_category,
           d_year,
           d_month_seq,
           SUM(net_profit) AS net_profit
    FROM (
      SELECT * FROM sales_store
      UNION ALL
      SELECT * FROM sales_catalog
      UNION ALL
      SELECT * FROM sales_web
    ) t
    GROUP BY i_category, d_year, d_month_seq
  ),
  returns_store AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  returns_catalog AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  returns_web AS (
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  returns_total AS (
    SELECT i_category,
           d_year,
           d_month_seq,
           SUM(net_loss) AS net_loss
    FROM (
      SELECT * FROM returns_store
      UNION ALL
      SELECT * FROM returns_catalog
      UNION ALL
      SELECT * FROM returns_web
    ) t
    GROUP BY i_category, d_year, d_month_seq
  )
SELECT s.i_category,
       s.d_year,
       s.d_month_seq,
       s.net_profit,
       COALESCE(r.net_loss, 0) AS net_loss,
       s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_after_returns
FROM sales_total s
LEFT JOIN returns_total r
  ON s.i_category = r.i_category
 AND s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year,
         s.d_month_seq,
         net_profit_after_returns DESC
LIMIT 100
