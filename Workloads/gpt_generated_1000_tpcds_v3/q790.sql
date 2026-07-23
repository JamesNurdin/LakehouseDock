WITH
  store_sales_agg AS (
    SELECT
      d_sales.d_year AS year,
      ca_store.ca_state AS state,
      p_store.p_promo_name AS promo_name,
      SUM(ss.ss_net_paid) AS total_store_sales,
      SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN date_dim d_promo_start_store ON p_store.p_start_date_sk = d_promo_start_store.d_date_sk
    JOIN date_dim d_promo_end_store ON p_store.p_end_date_sk = d_promo_end_store.d_date_sk
    JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    GROUP BY d_sales.d_year, ca_store.ca_state, p_store.p_promo_name
  ),
  store_returns_agg AS (
    SELECT
      d_return.d_year AS year,
      ca_return.ca_state AS state,
      SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY d_return.d_year, ca_return.ca_state
  ),
  web_sales_agg AS (
    SELECT
      d_ws_sold.d_year AS year,
      ca_bill.ca_state AS state,
      p_ws.p_promo_name AS promo_name,
      w_ws.w_warehouse_name AS warehouse,
      ws_site.web_name AS web_name,
      SUM(ws.ws_net_paid) AS total_web_sales,
      SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_web_open ON ws_site.web_open_date_sk = d_web_open.d_date_sk
    JOIN date_dim d_web_close ON ws_site.web_close_date_sk = d_web_close.d_date_sk
    JOIN date_dim d_promo_start_ws ON p_ws.p_start_date_sk = d_promo_start_ws.d_date_sk
    JOIN date_dim d_promo_end_ws ON p_ws.p_end_date_sk = d_promo_end_ws.d_date_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    GROUP BY d_ws_sold.d_year, ca_bill.ca_state, p_ws.p_promo_name, w_ws.w_warehouse_name, ws_site.web_name
  ),
  inventory_agg AS (
    SELECT
      d_inv.d_year AS year,
      w_inv.w_warehouse_name AS warehouse,
      SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
    GROUP BY d_inv.d_year, w_inv.w_warehouse_name
  )
SELECT
  ss.year,
  ss.state,
  ss.promo_name,
  ss.total_store_sales,
  ws.total_web_sales,
  COALESCE(sr.total_return_loss, 0) AS total_return_loss,
  COALESCE(i.total_inventory_qty, 0) AS total_inventory_qty,
  ws.warehouse,
  ws.web_name,
  CASE WHEN ss.total_store_profit + ws.total_web_profit > 0 THEN 'Profit' ELSE 'Loss' END AS overall_profit_category,
  (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_store_profit_all_time,
  ROW_NUMBER() OVER (PARTITION BY ss.state ORDER BY ss.total_store_sales DESC) AS state_sales_rank,
  (ss.total_store_sales + ws.total_web_sales) / NULLIF(i.total_inventory_qty, 0) AS sales_per_inventory
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.year = ws.year AND ss.state = ws.state AND ss.promo_name = ws.promo_name
LEFT JOIN store_returns_agg sr ON ss.year = sr.year AND ss.state = sr.state
LEFT JOIN inventory_agg i ON ss.year = i.year
WHERE ss.total_store_sales > 1000
ORDER BY ss.total_store_sales DESC
LIMIT 100
