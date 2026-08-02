WITH sales_data AS (
   SELECT
       d.d_date AS sales_date,
       s.s_store_id,
       s.s_store_name,
       cc.cc_name AS call_center_name,
       cp.cp_type AS catalog_page_type,
       'Catalog' AS channel,
       SUM(cs.cs_net_profit) AS net_profit,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   LEFT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk AND sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1 AND 12
     AND cc.cc_city = 'Mount Vernon'
     AND cp.cp_department = 'Books'
     AND s.s_state = 'CA'
     AND s.s_number_employees > 100
   GROUP BY d.d_date, s.s_store_id, s.s_store_name, cc.cc_name, cp.cp_type
   UNION ALL
   SELECT
       d.d_date AS sales_date,
       s.s_store_id,
       s.s_store_name,
       NULL AS call_center_name,
       NULL AS catalog_page_type,
       'Web' AS channel,
       SUM(ws.ws_net_profit) AS net_profit,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
       COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_ship_date_sk = d.d_date_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_item_sk = ws.ws_item_sk
                               AND wr.wr_order_number = ws.ws_order_number
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1 AND 12
     AND w.web_market_manager = 'Eldon Snow'
     AND s.s_state = 'CA'
     AND s.s_number_employees > 100
     AND ws.ws_quantity > 2
   GROUP BY d.d_date, s.s_store_id, s.s_store_name
)
SELECT
    sales_date,
    s_store_id,
    s_store_name,
    channel,
    net_profit,
    total_sales,
    total_return_loss,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY net_profit DESC) AS profit_rank
FROM sales_data
ORDER BY profit_rank, sales_date DESC
LIMIT 100
