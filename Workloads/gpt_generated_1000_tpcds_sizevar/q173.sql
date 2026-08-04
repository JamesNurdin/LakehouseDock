WITH
  ws_agg AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_web_site_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_sold_time_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_addr_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_hdemo_sk,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_net_paid > 1000
      AND ws.ws_sold_time_sk IS NOT NULL
      AND ws.ws_web_site_sk IS NOT NULL
    GROUP BY ws.ws_item_sk,
             ws.ws_web_site_sk,
             ws.ws_ship_mode_sk,
             ws.ws_warehouse_sk,
             ws.ws_sold_time_sk,
             ws.ws_bill_customer_sk,
             ws.ws_bill_addr_sk,
             ws.ws_bill_cdemo_sk,
             ws.ws_bill_hdemo_sk
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_net_paid) AS ss_total_net_paid,
      SUM(ss.ss_quantity) AS ss_total_qty
    FROM store_sales ss
    WHERE ss.ss_net_paid > 500
    GROUP BY ss.ss_item_sk
  ),
  web_returns_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS wr_total_return
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
    GROUP BY wr.wr_item_sk
  ),
  top_items AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      ws_agg.total_net_paid,
      ws_agg.total_quantity,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_buy_potential,
      sm.sm_type,
      w.w_warehouse_name,
      t.t_hour,
      ws_site.web_mkt_id,
      ssa.ss_total_net_paid,
      ssa.ss_total_qty,
      wra.wr_total_return,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws_agg.total_net_paid DESC) AS rnk
    FROM ws_agg
    JOIN item i ON i.i_item_sk = ws_agg.ws_item_sk
    JOIN web_site ws_site ON ws_site.web_site_sk = ws_agg.ws_web_site_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws_agg.ws_ship_mode_sk
    JOIN warehouse w ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
    JOIN time_dim t ON t.t_time_sk = ws_agg.ws_sold_time_sk
    JOIN customer_address ca ON ca.ca_address_sk = ws_agg.ws_bill_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ws_agg.ws_bill_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ws_agg.ws_bill_hdemo_sk
    JOIN customer cu ON cu.c_customer_sk = ws_agg.ws_bill_customer_sk
    LEFT JOIN store_sales_agg ssa ON ssa.ss_item_sk = ws_agg.ws_item_sk
    LEFT JOIN web_returns_agg wra ON wra.wr_item_sk = ws_agg.ws_item_sk
    WHERE i.i_category = 'Sports'
      AND ca.ca_country = 'United States'
      AND ws_site.web_mkt_id IN (3, 5)
      AND ws_agg.total_net_paid > 2000
  ),
  returned_items AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      ws_agg.total_net_paid,
      ws_agg.total_quantity,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_buy_potential,
      sm.sm_type,
      w.w_warehouse_name,
      t.t_hour,
      ws_site.web_mkt_id,
      ssa.ss_total_net_paid,
      ssa.ss_total_qty,
      wra.wr_total_return,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws_agg.total_net_paid DESC) AS rnk
    FROM ws_agg
    JOIN item i ON i.i_item_sk = ws_agg.ws_item_sk
    JOIN web_site ws_site ON ws_site.web_site_sk = ws_agg.ws_web_site_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws_agg.ws_ship_mode_sk
    JOIN warehouse w ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
    JOIN time_dim t ON t.t_time_sk = ws_agg.ws_sold_time_sk
    JOIN customer_address ca ON ca.ca_address_sk = ws_agg.ws_bill_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ws_agg.ws_bill_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ws_agg.ws_bill_hdemo_sk
    JOIN customer cu ON cu.c_customer_sk = ws_agg.ws_bill_customer_sk
    LEFT JOIN store_sales_agg ssa ON ssa.ss_item_sk = ws_agg.ws_item_sk
    LEFT JOIN web_returns_agg wra ON wra.wr_item_sk = ws_agg.ws_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = ws_agg.ws_item_sk
    WHERE sr.sr_return_amt > 0
  )
SELECT
  i_item_id,
  i_product_name,
  i_category,
  total_net_paid,
  total_quantity,
  ca_city,
  cd_gender,
  hd_buy_potential,
  sm_type,
  w_warehouse_name,
  t_hour,
  web_mkt_id,
  ss_total_net_paid,
  ss_total_qty,
  wr_total_return,
  rnk
FROM top_items
WHERE rnk = 1
EXCEPT
SELECT
  i_item_id,
  i_product_name,
  i_category,
  total_net_paid,
  total_quantity,
  ca_city,
  cd_gender,
  hd_buy_potential,
  sm_type,
  w_warehouse_name,
  t_hour,
  web_mkt_id,
  ss_total_net_paid,
  ss_total_qty,
  wr_total_return,
  rnk
FROM returned_items
WHERE rnk = 1
ORDER BY total_net_paid DESC
