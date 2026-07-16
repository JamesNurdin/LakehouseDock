WITH catalog_sales_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       cc.cc_name AS channel_dim,
       SUM(cs.cs_ext_sales_price) AS sales,
       SUM(cs.cs_ext_discount_amt) AS discount,
       SUM(cs.cs_net_profit) AS profit,
       SUM(cs.cs_quantity) AS qty,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       SUM(cs.cs_ext_tax) AS tax,
       SUM(COALESCE(p.p_cost, 0) * cs.cs_quantity) AS promo_cost
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, cc.cc_name
),
store_sales_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       s.s_store_name AS channel_dim,
       SUM(ss.ss_ext_sales_price) AS sales,
       SUM(ss.ss_ext_discount_amt) AS discount,
       SUM(ss.ss_net_profit) AS profit,
       SUM(ss.ss_quantity) AS qty,
       COUNT(DISTINCT ss.ss_ticket_number) AS orders,
       SUM(ss.ss_ext_tax) AS tax,
       SUM(COALESCE(p.p_cost, 0) * ss.ss_quantity) AS promo_cost
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, s.s_store_name
),
web_sales_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       wp.wp_url AS channel_dim,
       SUM(ws.ws_ext_sales_price) AS sales,
       SUM(ws.ws_ext_discount_amt) AS discount,
       SUM(ws.ws_net_profit) AS profit,
       SUM(ws.ws_quantity) AS qty,
       COUNT(DISTINCT ws.ws_order_number) AS orders,
       SUM(ws.ws_ext_tax) AS tax,
       SUM(COALESCE(p.p_cost, 0) * ws.ws_quantity) AS promo_cost
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, wp.wp_url
),
catalog_returns_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       SUM(cr.cr_return_amount) AS return_amount,
       SUM(cr.cr_return_quantity) AS return_qty,
       SUM(cr.cr_net_loss) AS net_loss,
       COUNT(DISTINCT cr.cr_order_number) AS return_orders
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
store_returns_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       SUM(sr.sr_return_amt) AS return_amount,
       SUM(sr.sr_return_quantity) AS return_qty,
       SUM(sr.sr_net_loss) AS net_loss,
       COUNT(DISTINCT sr.sr_ticket_number) AS return_orders
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
web_returns_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month,
       i.i_category AS category,
       i.i_brand AS brand,
       SUM(wr.wr_return_amt) AS return_amount,
       SUM(wr.wr_return_quantity) AS return_qty,
       SUM(wr.wr_net_loss) AS net_loss,
       COUNT(DISTINCT wr.wr_order_number) AS return_orders
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
combined_sales AS (
   SELECT
       cs.d_year,
       cs.month,
       cs.category,
       cs.brand,
       'Catalog' AS channel_type,
       cs.channel_dim,
       cs.sales,
       cs.discount,
       cs.profit,
       cs.qty,
       cs.orders,
       cs.tax,
       cs.promo_cost,
       COALESCE(cr.return_amount, 0) AS return_amount,
       COALESCE(cr.return_qty, 0) AS return_qty,
       COALESCE(cr.net_loss, 0) AS net_loss,
       COALESCE(cr.return_orders, 0) AS return_orders
   FROM catalog_sales_agg cs
   LEFT JOIN catalog_returns_agg cr
       ON cs.d_year = cr.d_year
       AND cs.month = cr.month
       AND cs.category = cr.category
       AND cs.brand = cr.brand
   UNION ALL
   SELECT
       ss.d_year,
       ss.month,
       ss.category,
       ss.brand,
       'Store' AS channel_type,
       ss.channel_dim,
       ss.sales,
       ss.discount,
       ss.profit,
       ss.qty,
       ss.orders,
       ss.tax,
       ss.promo_cost,
       COALESCE(sr.return_amount, 0) AS return_amount,
       COALESCE(sr.return_qty, 0) AS return_qty,
       COALESCE(sr.net_loss, 0) AS net_loss,
       COALESCE(sr.return_orders, 0) AS return_orders
   FROM store_sales_agg ss
   LEFT JOIN store_returns_agg sr
       ON ss.d_year = sr.d_year
       AND ss.month = sr.month
       AND ss.category = sr.category
       AND ss.brand = sr.brand
   UNION ALL
   SELECT
       ws.d_year,
       ws.month,
       ws.category,
       ws.brand,
       'Web' AS channel_type,
       ws.channel_dim,
       ws.sales,
       ws.discount,
       ws.profit,
       ws.qty,
       ws.orders,
       ws.tax,
       ws.promo_cost,
       COALESCE(wr.return_amount, 0) AS return_amount,
       COALESCE(wr.return_qty, 0) AS return_qty,
       COALESCE(wr.net_loss, 0) AS net_loss,
       COALESCE(wr.return_orders, 0) AS return_orders
   FROM web_sales_agg ws
   LEFT JOIN web_returns_agg wr
       ON ws.d_year = wr.d_year
       AND ws.month = wr.month
       AND ws.category = wr.category
       AND ws.brand = wr.brand
),
final_metrics AS (
   SELECT
       d_year,
       month,
       category,
       brand,
       channel_type,
       channel_dim,
       sales,
       discount,
       profit,
       qty,
       orders,
       tax,
       promo_cost,
       return_amount,
       return_qty,
       net_loss,
       return_orders,
       (sales - return_amount) AS net_sales,
       (profit - net_loss) AS net_profit,
       CASE WHEN orders > 0 THEN sales / orders ELSE 0 END AS avg_sale_per_order,
       CASE WHEN qty > 0 THEN profit / qty ELSE 0 END AS profit_per_item,
       ROW_NUMBER() OVER (PARTITION BY d_year, channel_type ORDER BY (sales - return_amount) DESC) AS rank_by_net_sales
   FROM combined_sales
)
SELECT
   d_year,
   month,
   category,
   brand,
   channel_type,
   channel_dim,
   net_sales,
   net_profit,
   qty,
   orders,
   avg_sale_per_order,
   profit_per_item,
   promo_cost,
   return_amount,
   return_qty,
   net_loss,
   rank_by_net_sales
FROM final_metrics
WHERE rank_by_net_sales <= 5
ORDER BY d_year, channel_type, rank_by_net_sales
