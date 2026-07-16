WITH sales_store AS (
   SELECT 
      'store' AS channel,
      ss.ss_sold_date_sk AS date_sk,
      d.d_year,
      ss.ss_store_sk AS location_sk,
      s.s_store_name AS loc_name,
      ss.ss_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS transaction_cnt,
      SUM(ss.ss_quantity) AS total_qty
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   GROUP BY ss.ss_sold_date_sk, d.d_year, ss.ss_store_sk, s.s_store_name, ss.ss_item_sk, i.i_product_name
), sales_catalog AS (
   SELECT 
      'catalog' AS channel,
      cs.cs_sold_date_sk AS date_sk,
      d.d_year,
      cs.cs_call_center_sk AS location_sk,
      cc.cc_name AS loc_name,
      cs.cs_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS transaction_cnt,
      SUM(cs.cs_quantity) AS total_qty
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY cs.cs_sold_date_sk, d.d_year, cs.cs_call_center_sk, cc.cc_name, cs.cs_item_sk, i.i_product_name
), sales_web AS (
   SELECT 
      'web' AS channel,
      ws.ws_sold_date_sk AS date_sk,
      d.d_year,
      ws.ws_web_page_sk AS location_sk,
      wp.wp_url AS loc_name,
      ws.ws_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS transaction_cnt,
      SUM(ws.ws_quantity) AS total_qty
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   GROUP BY ws.ws_sold_date_sk, d.d_year, ws.ws_web_page_sk, wp.wp_url, ws.ws_item_sk, i.i_product_name
), combined_sales AS (
   SELECT * FROM sales_store
   UNION ALL
   SELECT * FROM sales_catalog
   UNION ALL
   SELECT * FROM sales_web
), returns_store AS (
   SELECT 
      'store' AS channel,
      sr.sr_returned_date_sk AS date_sk,
      d.d_year,
      sr.sr_store_sk AS location_sk,
      s.s_store_name AS loc_name,
      sr.sr_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   GROUP BY sr.sr_returned_date_sk, d.d_year, sr.sr_store_sk, s.s_store_name, sr.sr_item_sk, i.i_product_name
), returns_catalog AS (
   SELECT 
      'catalog' AS channel,
      cr.cr_returned_date_sk AS date_sk,
      d.d_year,
      cr.cr_call_center_sk AS location_sk,
      cc.cc_name AS loc_name,
      cr.cr_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(cr.cr_return_amt_inc_tax) AS total_return_amt,
      SUM(cr.cr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   GROUP BY cr.cr_returned_date_sk, d.d_year, cr.cr_call_center_sk, cc.cc_name, cr.cr_item_sk, i.i_product_name
), returns_web AS (
   SELECT 
      'web' AS channel,
      wr.wr_returned_date_sk AS date_sk,
      d.d_year,
      wr.wr_web_page_sk AS location_sk,
      wp.wp_url AS loc_name,
      wr.wr_item_sk AS item_sk,
      i.i_product_name AS product_name,
      SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
      SUM(wr.wr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   GROUP BY wr.wr_returned_date_sk, d.d_year, wr.wr_web_page_sk, wp.wp_url, wr.wr_item_sk, i.i_product_name
), combined_returns AS (
   SELECT * FROM returns_store
   UNION ALL
   SELECT * FROM returns_catalog
   UNION ALL
   SELECT * FROM returns_web
), joined AS (
   SELECT 
      cs.channel,
      cs.date_sk,
      cs.d_year,
      cs.location_sk,
      COALESCE(cs.loc_name, 'UNKNOWN') AS loc_name,
      cs.item_sk,
      cs.product_name,
      cs.total_sales,
      cs.total_profit,
      cs.transaction_cnt,
      cs.total_qty,
      COALESCE(rt.total_return_amt, 0) AS total_return_amt,
      COALESCE(rt.total_return_loss, 0) AS total_return_loss,
      COALESCE(rt.return_cnt, 0) AS return_cnt,
      (cs.total_profit - COALESCE(rt.total_return_loss, 0)) / NULLIF(cs.total_sales, 0) AS profit_to_sales_ratio,
      CASE 
         WHEN (cs.total_profit - COALESCE(rt.total_return_loss, 0)) > 10000 THEN 'HIGH'
         WHEN (cs.total_profit - COALESCE(rt.total_return_loss, 0)) BETWEEN 0 AND 10000 THEN 'MEDIUM'
         ELSE 'LOW'
      END AS profit_category,
      CONCAT(cs.channel, ':', COALESCE(cs.loc_name, 'N/A')) AS channel_loc_key,
      (SELECT AVG(c2.total_sales) FROM combined_sales c2 WHERE c2.item_sk = cs.item_sk) AS avg_sales_across_channels
   FROM combined_sales cs
   LEFT JOIN combined_returns rt
     ON cs.channel = rt.channel
     AND cs.date_sk = rt.date_sk
     AND cs.location_sk = rt.location_sk
     AND cs.item_sk = rt.item_sk
)
SELECT *
FROM (
   SELECT
      channel,
      d_year,
      loc_name,
      product_name,
      total_sales,
      total_profit,
      total_return_amt,
      total_return_loss,
      profit_to_sales_ratio,
      profit_category,
      channel_loc_key,
      avg_sales_across_channels,
      SUM(total_sales) OVER (PARTITION BY channel) AS channel_total_sales,
      ROW_NUMBER() OVER (PARTITION BY channel ORDER BY profit_to_sales_ratio DESC) AS overall_rank
   FROM joined
   WHERE profit_to_sales_ratio IS NOT NULL
) t
WHERE t.overall_rank <= 10
ORDER BY t.channel, t.overall_rank
