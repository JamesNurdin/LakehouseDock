WITH cat_sales AS (
 SELECT d.d_year, d.d_month_seq, i.i_category,
        sum(cs.cs_net_profit) AS cat_profit,
        sum(cs.cs_quantity) AS cat_qty
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2000
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_sales_cte AS (
 SELECT d.d_year, d.d_month_seq, i.i_category,
        sum(ss.ss_net_profit) AS store_profit,
        sum(ss.ss_quantity) AS store_qty
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2000
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_cte AS (
 SELECT d.d_year, d.d_month_seq, i.i_category,
        sum(ws.ws_net_profit) AS web_profit,
        sum(ws.ws_quantity) AS web_qty
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2000
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_cte AS (
 SELECT d.d_year, d.d_month_seq, i.i_category,
        sum(rt.net_loss) AS total_return_loss
 FROM (
   SELECT cr_returned_date_sk AS date_sk, cr_item_sk AS item_sk, cr_net_loss AS net_loss FROM catalog_returns
   UNION ALL
   SELECT sr_returned_date_sk, sr_item_sk, sr_net_loss FROM store_returns
   UNION ALL
   SELECT wr_returned_date_sk, wr_item_sk, wr_net_loss FROM web_returns
 ) rt
 JOIN date_dim d ON rt.date_sk = d.d_date_sk
 JOIN item i ON rt.item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2000
 GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
 COALESCE(c.d_year, s.d_year, w.d_year) AS d_year,
 COALESCE(c.d_month_seq, s.d_month_seq, w.d_month_seq) AS d_month_seq,
 COALESCE(c.i_category, s.i_category, w.i_category) AS i_category,
 COALESCE(c.cat_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit_before_returns,
 COALESCE(r.total_return_loss, 0) AS total_return_loss,
 (COALESCE(c.cat_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) - COALESCE(r.total_return_loss, 0) AS net_profit,
 COALESCE(c.cat_qty, 0) + COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
 row_number() OVER (
   PARTITION BY COALESCE(c.d_year, s.d_year, w.d_year)
   ORDER BY ((COALESCE(c.cat_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) - COALESCE(r.total_return_loss, 0)) DESC
 ) AS rank_by_profit
FROM cat_sales c
FULL OUTER JOIN store_sales_cte s
  ON c.d_year = s.d_year AND c.d_month_seq = s.d_month_seq AND c.i_category = s.i_category
FULL OUTER JOIN web_sales_cte w
  ON COALESCE(c.d_year, s.d_year) = w.d_year
 AND COALESCE(c.d_month_seq, s.d_month_seq) = w.d_month_seq
 AND COALESCE(c.i_category, s.i_category) = w.i_category
LEFT JOIN returns_cte r
  ON COALESCE(c.d_year, s.d_year, w.d_year) = r.d_year
 AND COALESCE(c.d_month_seq, s.d_month_seq, w.d_month_seq) = r.d_month_seq
 AND COALESCE(c.i_category, s.i_category, w.i_category) = r.i_category
WHERE (COALESCE(c.cat_qty, 0) + COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) > 0
ORDER BY d_year, d_month_seq, net_profit DESC
LIMIT 100
