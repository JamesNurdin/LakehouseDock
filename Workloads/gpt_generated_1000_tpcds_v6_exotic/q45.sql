SELECT
  t_store.t_hour AS hour,
  i.i_category AS category,
  cd_store.cd_gender AS gender,
  SUM(ss.ss_net_profit) AS store_profit,
  SUM(cs.cs_net_profit) AS catalog_profit,
  SUM(ws.ws_net_profit) AS web_profit,
  SUM(cr.cr_net_loss) AS return_loss,
  (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) AS total_contribution
FROM tpcds.store_sales ss
  JOIN tpcds.time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
  JOIN tpcds.customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk

  -- Catalog sales linked through the same item dimension
  JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.time_dim t_catalog ON cs.cs_sold_time_sk = t_catalog.t_time_sk
  JOIN tpcds.promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
  JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN tpcds.customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN tpcds.warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk

  -- Catalog returns linked to catalog sales and item
  JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
  JOIN tpcds.customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  JOIN tpcds.customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
  JOIN tpcds.warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk

  -- Web sales linked through the same item dimension
  JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
  JOIN tpcds.promotion p_web ON ws.ws_promo_sk = p_web.p_promo_sk
  JOIN tpcds.customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
  JOIN tpcds.customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
  JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN tpcds.warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk

WHERE t_store.t_hour BETWEEN 8 AND 20
  AND i.i_category IS NOT NULL
GROUP BY ROLLUP (t_store.t_hour, i.i_category, cd_store.cd_gender)
HAVING (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) > 0
ORDER BY t_store.t_hour NULLS LAST, i.i_category, cd_store.cd_gender
LIMIT 100
