WITH base AS (
  SELECT
    s.s_store_name,
    s.s_store_sk,
    i.i_item_id,
    i.i_item_sk,
    d_sold.d_year,
    ss.ss_quantity,
    ss.ss_net_profit,
    cr.cr_order_number,
    wr.wr_order_number AS wr_order_num,
    sr.sr_return_quantity,
    ss.ss_ticket_number
  FROM store_sales ss
  JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
  JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
  JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
  LEFT JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
)
SELECT
  store_name,
  item_id,
  sale_year,
  total_quantity,
  total_profit,
  CASE WHEN total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
  catalog_return_cnt,
  web_return_cnt,
  ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT
    s_store_name AS store_name,
    i_item_id AS item_id,
    d_year AS sale_year,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_profit) AS total_profit,
    COUNT(DISTINCT cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT wr_order_num) AS web_return_cnt
  FROM base
  GROUP BY s_store_name, i_item_id, d_year
) t
ORDER BY total_profit DESC
LIMIT 100
