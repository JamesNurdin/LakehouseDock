WITH base AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       i.i_current_price,
       t.t_time_sk,
       t.t_hour,
       s.s_store_sk,
       s.s_state,
       wsite.web_site_sk,
       wsite.web_market_manager,
       cd.cd_demo_sk,
       hd.hd_demo_sk,
       ss.ss_sold_date_sk,
       ss.ss_ext_sales_price AS store_sales_amt,
       ss.ss_net_profit AS store_profit,
       ws.ws_sold_date_sk,
       ws.ws_ext_sales_price AS web_sales_amt,
       ws.ws_net_profit AS web_profit,
       cr.cr_return_amount,
       cr.cr_net_loss,
       sr.sr_return_amt,
       sr.sr_net_loss,
       wr.wr_return_amt,
       wr.wr_net_loss
   FROM item i
   JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
   LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
   LEFT JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
   WHERE t.t_hour BETWEEN 8 AND 17
     AND i.i_current_price > 10
     AND s.s_state = 'CA'
     AND wsite.web_market_manager = 'Scott Bryant'
)
SELECT
    i_item_id,
    i_product_name,
    t_hour,
    s_state,
    web_market_manager,
    SUM(store_sales_amt) AS total_store_sales,
    SUM(web_sales_amt) AS total_web_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    (SUM(store_sales_amt) + SUM(web_sales_amt) - COALESCE(SUM(cr_return_amount), 0) - COALESCE(SUM(sr_return_amt), 0) - COALESCE(SUM(wr_return_amt), 0)) AS net_sales,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY (SUM(store_sales_amt) + SUM(web_sales_amt) - COALESCE(SUM(cr_return_amount), 0) - COALESCE(SUM(sr_return_amt), 0) - COALESCE(SUM(wr_return_amt), 0)) DESC) AS sales_rank
FROM base
GROUP BY i_item_id, i_product_name, t_hour, s_state, web_market_manager
ORDER BY t_hour, sales_rank
LIMIT 100
