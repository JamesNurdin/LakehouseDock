WITH joined_data AS (
  SELECT
    ss.ss_net_paid AS ss_net_paid,
    ws.ws_net_paid AS ws_net_paid,
    cr.cr_net_loss AS cr_net_loss,
    i_ss.i_category AS item_category,
    i_ss.i_brand AS item_brand,
    dd_ss.d_year AS sales_year,
    cp.cp_department AS department,
    CASE WHEN ss.ss_sales_price > 20 THEN 'high' ELSE 'low' END AS price_level,
    cd_ss.cd_gender AS gender,
    ca_ss.ca_state AS state
  FROM store_sales ss
  JOIN date_dim dd_ss ON ss.ss_sold_date_sk = dd_ss.d_date_sk
  JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
  JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
  JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = dd_ss.d_date_sk
  JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
  JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = dd_ss.d_date_sk
  JOIN date_dim dd_cr ON cr.cr_returned_date_sk = dd_cr.d_date_sk
  JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
  JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
  JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim dd_cp_start ON cp.cp_start_date_sk = dd_cp_start.d_date_sk
  JOIN date_dim dd_cp_end ON cp.cp_end_date_sk = dd_cp_end.d_date_sk
)
SELECT
  sales_year,
  item_category,
  department,
  price_level,
  SUM(ss_net_paid) AS total_store_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  SUM(cr_net_loss) AS total_return_loss,
  (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(cr_net_loss)) AS net_revenue,
  CASE
    WHEN (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(cr_net_loss)) > 50000 THEN 'Very High'
    WHEN (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(cr_net_loss)) > 20000 THEN 'High'
    ELSE 'Moderate'
  END AS revenue_category
FROM joined_data
GROUP BY
  sales_year,
  item_category,
  department,
  price_level
HAVING
  (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(cr_net_loss)) > 10000
ORDER BY net_revenue DESC
LIMIT 100
