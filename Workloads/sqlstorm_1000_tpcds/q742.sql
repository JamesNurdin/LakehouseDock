WITH store_data AS (
 SELECT i.i_item_id,
        i.i_item_desc,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_id, i.i_item_desc, d.d_year
),
web_data AS (
 SELECT i.i_item_id,
        i.i_item_desc,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_id, i.i_item_desc, d.d_year
),
catalog_data AS (
 SELECT i.i_item_id,
        i.i_item_desc,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_id, i.i_item_desc, d.d_year
),
return_data AS (
 SELECT i.i_item_id,
        i.i_item_desc,
        d.d_year,
        SUM(r.net_loss) AS total_return_loss
 FROM (
   SELECT sr.sr_item_sk AS item_sk, sr.sr_returned_date_sk AS date_sk, sr.sr_net_loss AS net_loss FROM store_returns sr
   UNION ALL
   SELECT cr.cr_item_sk, cr.cr_returned_date_sk, cr.cr_net_loss FROM catalog_returns cr
   UNION ALL
   SELECT wr.wr_item_sk, wr.wr_returned_date_sk, wr.wr_net_loss FROM web_returns wr
 ) r
 JOIN item i ON r.item_sk = i.i_item_sk
 JOIN date_dim d ON r.date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_id, i.i_item_desc, d.d_year
)
SELECT 
  COALESCE(s.i_item_id, w.i_item_id, c.i_item_id, r.i_item_id) AS item_id,
  COALESCE(s.i_item_desc, w.i_item_desc, c.i_item_desc, r.i_item_desc) AS item_desc,
  s.store_profit,
  w.web_profit,
  c.catalog_profit,
  r.total_return_loss,
  (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit,
  CASE 
    WHEN (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0)) > 0 THEN 
      ((COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0) - COALESCE(r.total_return_loss, 0))
        / (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0))) * 100
    ELSE NULL 
  END AS profit_margin_pct
FROM store_data s
FULL OUTER JOIN web_data w ON s.i_item_id = w.i_item_id
FULL OUTER JOIN catalog_data c ON COALESCE(s.i_item_id, w.i_item_id) = c.i_item_id
FULL OUTER JOIN return_data r ON COALESCE(s.i_item_id, w.i_item_id, c.i_item_id) = r.i_item_id
WHERE (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0) - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY net_profit DESC
LIMIT 100
