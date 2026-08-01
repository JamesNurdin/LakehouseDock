WITH joined_data AS (
   SELECT
      ss.ss_ticket_number,
      s.s_store_name,
      s.s_city,
      s.s_state,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      i.i_item_id,
      d.d_month_seq,
      d.d_year,
      ss.ss_net_profit AS store_net_profit,
      ss.ss_ext_sales_price AS store_ext_sales,
      c_sales.cd_credit_rating AS cust_credit_rating,
      c_sales.cd_purchase_estimate AS cust_purchase_estimate,
      ws.ws_order_number,
      ws.ws_net_profit AS web_net_profit,
      ws.ws_ext_sales_price AS web_ext_sales,
      we.web_name,
      sp.sm_type AS ship_type,
      w.w_warehouse_name,
      wp.wp_url,
      wp.wp_type,
      sr.sr_net_loss AS store_return_loss,
      wr.wr_net_loss AS web_return_loss,
      d_sr.d_year AS sr_year,
      d_wr.d_year AS wr_year
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics c_sales ON ss.ss_cdemo_sk = c_sales.cd_demo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
   LEFT JOIN customer_demographics c_ret ON sr.sr_cdemo_sk = c_ret.cd_demo_sk
   LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
   LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
   -- Web side joins
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = ss.ss_item_sk
   JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
   JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
   JOIN customer_demographics c_bill ON ws.ws_bill_cdemo_sk = c_bill.cd_demo_sk
   JOIN ship_mode sp ON ws.ws_ship_mode_sk = sp.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
   LEFT JOIN customer_demographics c_refunded ON wr.wr_refunded_cdemo_sk = c_refunded.cd_demo_sk
   LEFT JOIN customer_demographics c_returning ON wr.wr_returning_cdemo_sk = c_returning.cd_demo_sk
   LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
   LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
   LEFT JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
   -- Catalog page joins
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
   JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
   -- Store closed date
   JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
   -- Web site dates
   JOIN date_dim d_ws_open ON we.web_open_date_sk = d_ws_open.d_date_sk
   JOIN date_dim d_ws_close ON we.web_close_date_sk = d_ws_close.d_date_sk
   -- Web page dates
   JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   WHERE d.d_year = 2001
     AND c_sales.cd_credit_rating = 'High Risk'
     AND i.i_current_price > 100
     AND EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_store_sk = s.s_store_sk AND sr2.sr_net_loss > 500)
),
aggregated AS (
   SELECT
       s_store_name,
       s_city,
       s_state,
       i_category,
       i_brand,
       d_month_seq,
       SUM(store_net_profit) AS total_store_profit,
       SUM(web_net_profit) AS total_web_profit,
       AVG(CASE WHEN cust_credit_rating = 'Low Risk' THEN 1 ELSE 0 END) AS low_risk_customer_ratio,
       COUNT(DISTINCT ss_ticket_number) AS distinct_transactions,
       CASE 
           WHEN SUM(store_net_profit) > 10000 THEN 'High Store Profit'
           WHEN SUM(web_net_profit) > 10000 THEN 'High Web Profit'
           ELSE 'Moderate Profit'
       END AS profit_category
   FROM joined_data
   GROUP BY s_store_name, s_city, s_state, i_category, i_brand, d_month_seq
   HAVING SUM(store_net_profit) > 0
)
SELECT
   s_store_name,
   s_city,
   s_state,
   i_category,
   i_brand,
   d_month_seq,
   total_store_profit,
   total_web_profit,
   low_risk_customer_ratio,
   distinct_transactions,
   profit_category
FROM aggregated
ORDER BY total_store_profit DESC, total_web_profit DESC
LIMIT 100
