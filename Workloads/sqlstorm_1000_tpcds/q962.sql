WITH store_sales_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(ss.ss_net_paid) AS store_net_paid,
         SUM(ss.ss_net_profit) AS store_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
),
web_sales_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(ws.ws_net_paid) AS web_net_paid,
         SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
),
catalog_sales_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(cs.cs_net_paid) AS catalog_net_paid,
         SUM(cs.cs_net_profit) AS catalog_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
),
store_returns_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(sr.sr_net_loss) AS store_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
),
web_returns_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(wr.wr_net_loss) AS web_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
),
catalog_returns_agg AS (
  SELECT i.i_item_sk,
         d.d_year,
         SUM(cr.cr_net_loss) AS catalog_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_sk, d.d_year
)
SELECT i.i_item_id,
       i.i_product_name,
       COALESCE(ss.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0) + COALESCE(cs.catalog_net_paid, 0) AS total_net_paid,
       COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) AS total_net_profit,
       COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) AS total_net_loss,
       (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0)) -
       (COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0)) AS net_profit_after_returns,
       ROW_NUMBER() OVER (
         ORDER BY (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0)) -
                  (COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0)) DESC
       ) AS profit_rank
FROM item i
LEFT JOIN store_sales_agg ss ON i.i_item_sk = ss.i_item_sk
LEFT JOIN web_sales_agg ws ON i.i_item_sk = ws.i_item_sk
LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.i_item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.i_item_sk
LEFT JOIN web_returns_agg wr ON i.i_item_sk = wr.i_item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.i_item_sk
WHERE COALESCE(ss.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0) + COALESCE(cs.catalog_net_paid, 0) > 0
ORDER BY net_profit_after_returns DESC
FETCH FIRST 100 ROWS ONLY
