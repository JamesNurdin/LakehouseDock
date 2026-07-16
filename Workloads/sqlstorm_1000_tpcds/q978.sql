WITH
store_sales_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     s.s_store_name AS entity,
     'store' AS channel,
     SUM(ss_ext_sales_price) AS total_sales,
     SUM(ss_net_profit) AS total_profit,
     SUM(ss_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT ss_ticket_number) AS orders,
     AVG(ss_quantity) AS avg_qty_per_order
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY d.d_year, d.d_month_seq, s.s_store_name
),
catalog_sales_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     cc.cc_name AS entity,
     'catalog' AS channel,
     SUM(cs_ext_sales_price) AS total_sales,
     SUM(cs_net_profit) AS total_profit,
     SUM(cs_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT cs_order_number) AS orders,
     AVG(cs_quantity) AS avg_qty_per_order
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   GROUP BY d.d_year, d.d_month_seq, cc.cc_name
),
web_sales_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     wp.wp_url AS entity,
     'web' AS channel,
     SUM(ws_ext_sales_price) AS total_sales,
     SUM(ws_net_profit) AS total_profit,
     SUM(ws_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT ws_order_number) AS orders,
     AVG(ws_quantity) AS avg_qty_per_order
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   GROUP BY d.d_year, d.d_month_seq, wp.wp_url
),
sales_agg AS (
   SELECT * FROM store_sales_agg
   UNION ALL
   SELECT * FROM catalog_sales_agg
   UNION ALL
   SELECT * FROM web_sales_agg
),
store_returns_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     s.s_store_name AS entity,
     'store' AS channel,
     SUM(sr_return_amt) AS return_amount,
     SUM(sr_net_loss) AS net_loss,
     COUNT(DISTINCT sr_ticket_number) AS return_orders
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   GROUP BY d.d_year, d.d_month_seq, s.s_store_name
),
catalog_returns_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     cc.cc_name AS entity,
     'catalog' AS channel,
     SUM(cr_return_amount) AS return_amount,
     SUM(cr_net_loss) AS net_loss,
     COUNT(DISTINCT cr_order_number) AS return_orders
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   GROUP BY d.d_year, d.d_month_seq, cc.cc_name
),
web_returns_agg AS (
   SELECT
     d.d_year,
     d.d_month_seq,
     wp.wp_url AS entity,
     'web' AS channel,
     SUM(wr_return_amt) AS return_amount,
     SUM(wr_net_loss) AS net_loss,
     COUNT(DISTINCT wr_order_number) AS return_orders
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   GROUP BY d.d_year, d.d_month_seq, wp.wp_url
),
returns_agg AS (
   SELECT * FROM store_returns_agg
   UNION ALL
   SELECT * FROM catalog_returns_agg
   UNION ALL
   SELECT * FROM web_returns_agg
),
final AS (
   SELECT
     s.d_year,
     s.d_month_seq,
     s.channel,
     s.entity,
     s.total_sales,
     s.total_profit,
     s.total_discount,
     s.orders,
     s.avg_qty_per_order,
     COALESCE(r.return_amount, 0) AS return_amount,
     COALESCE(r.net_loss, 0) AS net_loss,
     COALESCE(r.return_orders, 0) AS return_orders,
     (s.total_sales - COALESCE(r.return_amount, 0)) AS net_sales,
     (s.total_profit - COALESCE(r.net_loss, 0)) AS net_profit_after_returns,
     CASE WHEN s.total_sales <> 0 THEN (s.total_profit - COALESCE(r.net_loss, 0)) / s.total_sales ELSE NULL END AS profit_ratio,
     RANK() OVER (PARTITION BY s.d_year, s.d_month_seq, s.channel ORDER BY s.total_sales DESC) AS sales_rank
   FROM sales_agg s
   LEFT JOIN returns_agg r
     ON s.d_year = r.d_year
     AND s.d_month_seq = r.d_month_seq
     AND s.entity = r.entity
     AND s.channel = r.channel
)
SELECT *
FROM final
ORDER BY final.d_year, final.d_month_seq, final.channel, final.sales_rank
