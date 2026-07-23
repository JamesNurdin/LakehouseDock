WITH base AS (
   SELECT
      cs.cs_sold_date_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      cc.cc_name,
      cc.cc_gmt_offset,
      cc.cc_rec_start_date,
      sm.sm_type,
      w.w_warehouse_name,
      w.w_state,
      ca.ca_state,
      ca.ca_country,
      cd.cd_gender,
      td.t_hour,
      wsite.web_market_manager
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
      AND cr.cr_returned_time_sk = td.t_time_sk
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      AND ws.ws_bill_addr_sk = ca.ca_address_sk
      AND ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_returned_time_sk = td.t_time_sk
   WHERE
      cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND w.w_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
      AND td.t_hour BETWEEN 8 AND 17
      AND wsite.web_market_manager IN ('Jeffrey Martin','John Sheppard')
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cs.cs_ext_sales_price > 1000
),
sub1 AS (
   SELECT
      w_warehouse_name AS warehouse,
      cs_sold_date_sk AS sale_date,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit,
      'catalog' AS source
   FROM base
   GROUP BY w_warehouse_name, cs_sold_date_sk
),
sub2 AS (
   SELECT
      w_warehouse_name AS warehouse,
      ws_sold_date_sk AS sale_date,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit) AS total_profit,
      'web' AS source
   FROM base
   GROUP BY w_warehouse_name, ws_sold_date_sk
),
unioned AS (
   SELECT warehouse, sale_date, total_sales, total_profit, source FROM sub1
   UNION ALL
   SELECT warehouse, sale_date, total_sales, total_profit, source FROM sub2
),
agg AS (
   SELECT
      warehouse,
      AVG(total_sales) AS avg_daily_sales,
      SUM(total_profit) AS sum_profit,
      COUNT(DISTINCT sale_date) AS active_days
   FROM unioned
   GROUP BY warehouse
   HAVING SUM(total_profit) > 0
)
SELECT
   warehouse,
   avg_daily_sales,
   sum_profit,
   active_days
FROM agg
ORDER BY avg_daily_sales DESC
LIMIT 100
