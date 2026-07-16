WITH
sales_cat AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  cc.cc_state AS state,
  i.i_category,
  i.i_brand,
  'Catalog' AS channel,
  SUM(cs.cs_net_paid) AS total_sales,
  SUM(cs.cs_net_profit) AS total_profit,
  SUM(cs.cs_quantity) AS total_quantity,
  SUM(cs.cs_coupon_amt) AS total_coupon,
  SUM(cs.cs_ext_discount_amt) AS total_discount
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_category, i.i_brand
),
sales_store AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  s.s_state AS state,
  i.i_category,
  i.i_brand,
  'Store' AS channel,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  SUM(ss.ss_quantity) AS total_quantity,
  SUM(ss.ss_coupon_amt) AS total_coupon,
  SUM(ss.ss_ext_discount_amt) AS total_discount
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category, i.i_brand
),
sales_web AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  w.web_state AS state,
  i.i_category,
  i.i_brand,
  'Web' AS channel,
  SUM(ws.ws_net_paid) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_coupon_amt) AS total_coupon,
  SUM(ws.ws_ext_discount_amt) AS total_discount
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, w.web_state, i.i_category, i.i_brand
),
sales_base AS (
 SELECT * FROM sales_cat
 UNION ALL
 SELECT * FROM sales_store
 UNION ALL
 SELECT * FROM sales_web
),
returns_cat AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  cc.cc_state AS state,
  i.i_category,
  i.i_brand,
  'Catalog' AS channel,
  SUM(cr.cr_return_quantity) AS total_return_qty,
  SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_category, i.i_brand
),
returns_store AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  s.s_state AS state,
  i.i_category,
  i.i_brand,
  'Store' AS channel,
  SUM(sr.sr_return_quantity) AS total_return_qty,
  SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
  SUM(sr.sr_net_loss) AS total_return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category, i.i_brand
),
returns_web AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  w.web_state AS state,
  i.i_category,
  i.i_brand,
  'Web' AS channel,
  SUM(wr.wr_return_quantity) AS total_return_qty,
  SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_return_loss
 FROM web_returns wr
 JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, w.web_state, i.i_category, i.i_brand
),
returns_base AS (
 SELECT * FROM returns_cat
 UNION ALL
 SELECT * FROM returns_store
 UNION ALL
 SELECT * FROM returns_web
),
combined AS (
 SELECT
  s.d_year,
  s.d_month_seq,
  s.state,
  s.i_category,
  s.i_brand,
  s.channel,
  s.total_sales,
  s.total_profit,
  s.total_quantity,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
  (s.total_sales - COALESCE(r.total_return_amount, 0))
    - LAG(s.total_sales - COALESCE(r.total_return_amount, 0)) OVER (PARTITION BY s.state, s.channel ORDER BY s.d_year, s.d_month_seq) AS net_sales_mom_change,
  ROW_NUMBER() OVER (PARTITION BY s.state, s.channel ORDER BY s.total_sales DESC) AS sales_rank
 FROM sales_base s
 LEFT JOIN returns_base r
   ON s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
  AND s.state = r.state
  AND s.i_category = r.i_category
  AND s.i_brand = r.i_brand
  AND s.channel = r.channel
 WHERE s.d_year = 2001
   AND s.state IS NOT NULL
)
SELECT *
FROM combined
WHERE sales_rank <= 10
ORDER BY d_year, d_month_seq, state, channel, sales_rank
