WITH sales_agg AS (
   SELECT
     d.d_year,
     d.d_quarter_seq,
     st.s_state,
     i.i_category,
     i.i_brand,
     SUM(ss.ss_net_paid) AS total_store_sales,
     SUM(cs.cs_net_paid) AS total_catalog_sales,
     SUM(ws.ws_net_paid) AS total_web_sales,
     SUM(ss.ss_net_profit) AS total_store_profit,
     SUM(cs.cs_net_profit) AS total_catalog_profit,
     SUM(ws.ws_net_profit) AS total_web_profit,
     COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
     COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt,
     COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
   FROM date_dim d
   LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store st ON st.s_store_sk = ss.ss_store_sk
   LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON i.i_item_sk = COALESCE(ss.ss_item_sk, cs.cs_item_sk, ws.ws_item_sk)
   WHERE d.d_year BETWEEN 1999 AND 2002
   GROUP BY d.d_year, d.d_quarter_seq, st.s_state, i.i_category, i.i_brand
),
returns_agg AS (
   SELECT
     d.d_year,
     d.d_quarter_seq,
     st.s_state,
     i.i_category,
     i.i_brand,
     SUM(sr.sr_net_loss) AS store_return_loss,
     SUM(cr.cr_net_loss) AS catalog_return_loss,
     SUM(wr.wr_net_loss) AS web_return_loss,
     COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
     COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
     COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
   FROM date_dim d
   LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store st ON st.s_store_sk = sr.sr_store_sk
   LEFT JOIN item i ON i.i_item_sk = sr.sr_item_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   GROUP BY d.d_year, d.d_quarter_seq, st.s_state, i.i_category, i.i_brand
)
SELECT
   s.d_year,
   s.d_quarter_seq,
   s.s_state,
   s.i_category,
   s.i_brand,
   s.total_store_sales,
   s.total_catalog_sales,
   s.total_web_sales,
   s.total_store_profit,
   s.total_catalog_profit,
   s.total_web_profit,
   r.store_return_loss,
   r.catalog_return_loss,
   r.web_return_loss,
   (s.total_store_sales - COALESCE(r.store_return_loss, 0)) AS net_store_sales,
   (s.total_catalog_sales - COALESCE(r.catalog_return_loss, 0)) AS net_catalog_sales,
   (s.total_web_sales - COALESCE(r.web_return_loss, 0)) AS net_web_sales,
   RANK() OVER (PARTITION BY s.d_year, s.d_quarter_seq ORDER BY (s.total_store_sales + s.total_catalog_sales + s.total_web_sales) DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_quarter_seq = r.d_quarter_seq
 AND s.s_state = r.s_state
 AND s.i_category = r.i_category
 AND s.i_brand = r.i_brand
ORDER BY s.d_year, s.d_quarter_seq, sales_rank
LIMIT 100
