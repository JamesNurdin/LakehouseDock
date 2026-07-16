WITH store_sales_agg AS (
 SELECT d.d_year,
        s.s_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_coupon_amt) AS total_coupon
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, s.s_store_id, i.i_item_id
),
store_returns_agg AS (
 SELECT d.d_year,
        s.s_store_id,
        i.i_item_id,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, s.s_store_id, i.i_item_id
),
catalog_sales_agg AS (
 SELECT d.d_year,
        cp.cp_catalog_page_id,
        i.i_item_id,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_coupon_amt) AS total_coupon
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, cp.cp_catalog_page_id, i.i_item_id
),
catalog_returns_agg AS (
 SELECT d.d_year,
        cp.cp_catalog_page_id,
        i.i_item_id,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, cp.cp_catalog_page_id, i.i_item_id
),
web_sales_agg AS (
 SELECT d.d_year,
        wp.wp_web_page_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_coupon_amt) AS total_coupon
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, wp.wp_web_page_id, i.i_item_id
),
web_returns_agg AS (
 SELECT d.d_year,
        wp.wp_web_page_id,
        i.i_item_id,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, wp.wp_web_page_id, i.i_item_id
),
combined_sales AS (
 SELECT
   'store' AS channel,
   ss.d_year,
   ss.s_store_id AS channel_id,
   ss.i_item_id,
   ss.total_quantity,
   ss.total_sales,
   ss.total_profit,
   ss.total_discount,
   ss.total_coupon,
   COALESCE(sr.total_return_qty, 0) AS return_quantity,
   COALESCE(sr.total_return_amt, 0) AS return_amount,
   COALESCE(sr.total_return_loss, 0) AS return_loss
 FROM store_sales_agg ss
 LEFT JOIN store_returns_agg sr
   ON ss.d_year = sr.d_year
  AND ss.s_store_id = sr.s_store_id
  AND ss.i_item_id = sr.i_item_id
 UNION ALL
 SELECT
   'catalog',
   cs.d_year,
   cs.cp_catalog_page_id AS channel_id,
   cs.i_item_id,
   cs.total_quantity,
   cs.total_sales,
   cs.total_profit,
   cs.total_discount,
   cs.total_coupon,
   COALESCE(cr.total_return_qty, 0),
   COALESCE(cr.total_return_amt, 0),
   COALESCE(cr.total_return_loss, 0)
 FROM catalog_sales_agg cs
 LEFT JOIN catalog_returns_agg cr
   ON cs.d_year = cr.d_year
  AND cs.cp_catalog_page_id = cr.cp_catalog_page_id
  AND cs.i_item_id = cr.i_item_id
 UNION ALL
 SELECT
   'web',
   ws.d_year,
   ws.wp_web_page_id AS channel_id,
   ws.i_item_id,
   ws.total_quantity,
   ws.total_sales,
   ws.total_profit,
   ws.total_discount,
   ws.total_coupon,
   COALESCE(wr.total_return_qty, 0),
   COALESCE(wr.total_return_amt, 0),
   COALESCE(wr.total_return_loss, 0)
 FROM web_sales_agg ws
 LEFT JOIN web_returns_agg wr
   ON ws.d_year = wr.d_year
  AND ws.wp_web_page_id = wr.wp_web_page_id
  AND ws.i_item_id = wr.i_item_id
)
SELECT
  channel,
  d_year,
  channel_id,
  i_item_id,
  total_quantity,
  total_sales,
  total_profit - return_loss AS net_profit,
  total_discount,
  total_coupon,
  return_quantity,
  return_amount,
  ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY (total_profit - return_loss) DESC) AS profit_rank
FROM combined_sales
WHERE d_year BETWEEN 1999 AND 2002
ORDER BY channel, d_year, profit_rank
LIMIT 100
