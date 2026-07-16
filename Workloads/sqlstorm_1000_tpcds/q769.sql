WITH
store_sales_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(ss.ss_net_profit) AS profit,
   SUM(ss.ss_ext_sales_price) AS sales,
   COUNT(*) AS txn_cnt
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
catalog_sales_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(cs.cs_net_profit) AS profit,
   SUM(cs.cs_ext_sales_price) AS sales,
   COUNT(*) AS txn_cnt
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
web_sales_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(ws.ws_net_profit) AS profit,
   SUM(ws.ws_ext_sales_price) AS sales,
   COUNT(*) AS txn_cnt
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
sales_combined AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
sales_monthly_agg AS (
 SELECT
   i_category,
   i_category_id,
   d_year,
   d_moy,
   SUM(profit) AS total_profit,
   SUM(sales) AS total_sales,
   SUM(txn_cnt) AS total_txn_cnt
 FROM sales_combined
 GROUP BY i_category, i_category_id, d_year, d_moy
),
store_returns_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(sr.sr_net_loss) AS loss,
   SUM(sr.sr_return_quantity) AS return_qty,
   COUNT(*) AS return_txn_cnt
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
catalog_returns_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(cr.cr_net_loss) AS loss,
   SUM(cr.cr_return_quantity) AS return_qty,
   COUNT(*) AS return_txn_cnt
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
web_returns_agg AS (
 SELECT
   i.i_category,
   i.i_category_id,
   d.d_year,
   d.d_moy,
   SUM(wr.wr_net_loss) AS loss,
   SUM(wr.wr_return_quantity) AS return_qty,
   COUNT(*) AS return_txn_cnt
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY i.i_category, i.i_category_id, d.d_year, d.d_moy
),
returns_combined AS (
 SELECT * FROM store_returns_agg
 UNION ALL
 SELECT * FROM catalog_returns_agg
 UNION ALL
 SELECT * FROM web_returns_agg
),
returns_monthly_agg AS (
 SELECT
   i_category,
   i_category_id,
   d_year,
   d_moy,
   SUM(loss) AS total_loss,
   SUM(return_qty) AS total_return_qty,
   SUM(return_txn_cnt) AS total_return_txn_cnt
 FROM returns_combined
 GROUP BY i_category, i_category_id, d_year, d_moy
)
SELECT
  s.i_category,
  s.d_year,
  s.d_moy,
  s.total_sales,
  s.total_profit,
  COALESCE(r.total_loss, 0) AS total_loss,
  (s.total_profit - COALESCE(r.total_loss, 0)) AS net_profit,
  ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_moy ORDER BY (s.total_profit - COALESCE(r.total_loss, 0)) DESC) AS profit_rank_in_month
FROM sales_monthly_agg s
LEFT JOIN returns_monthly_agg r
  ON s.i_category_id = r.i_category_id
  AND s.d_year = r.d_year
  AND s.d_moy = r.d_moy
WHERE s.total_sales > 1000000
ORDER BY s.d_year, s.d_moy, profit_rank_in_month
LIMIT 100
