WITH joined AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_class,
    w.w_warehouse_name,
    d_cs.d_year,
    COALESCE(cs.cs_net_profit, 0) AS cs_profit,
    COALESCE(ss.ss_net_profit, 0) AS ss_profit,
    COALESCE(ws.ws_net_profit, 0) AS ws_profit,
    COALESCE(wr.wr_net_loss, 0) AS wr_loss
  FROM tpcds.customer c
  JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
  LEFT JOIN tpcds.call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
  LEFT JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
  LEFT JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
  LEFT JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
  LEFT JOIN tpcds.reason r ON r.r_reason_sk = wr.wr_reason_sk
  LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = cs.cs_item_sk
  LEFT JOIN tpcds.date_dim d_cs ON d_cs.d_date_sk = cs.cs_sold_date_sk
  LEFT JOIN tpcds.date_dim d_ss ON d_ss.d_date_sk = ss.ss_sold_date_sk
  LEFT JOIN tpcds.date_dim d_ws ON d_ws.d_date_sk = ws.ws_sold_date_sk
  LEFT JOIN tpcds.date_dim d_wr ON d_wr.d_date_sk = wr.wr_returned_date_sk
  LEFT JOIN tpcds.date_dim d_inv ON d_inv.d_date_sk = inv.inv_date_sk
  WHERE d_cs.d_year = 2022
    AND i.i_class = 'furniture'
    AND w.w_state = 'CA'
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  i_item_id,
  i_class,
  w_warehouse_name,
  d_year,
  (cs_profit + ss_profit + ws_profit - wr_loss) AS total_profit,
  RANK() OVER (ORDER BY (cs_profit + ss_profit + ws_profit - wr_loss) DESC) AS profit_rank,
  AVG(cs_profit + ss_profit + ws_profit - wr_loss) OVER (
    PARTITION BY i_class
    ORDER BY (cs_profit + ss_profit + ws_profit - wr_loss)
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg_profit,
  (
    SELECT AVG(cs2.cs_net_profit)
    FROM tpcds.catalog_sales cs2
    JOIN tpcds.date_dim d2 ON d2.d_date_sk = cs2.cs_sold_date_sk
    WHERE d2.d_year = 2022
  ) AS avg_catalog_profit
FROM joined
ORDER BY profit_rank
LIMIT 100
