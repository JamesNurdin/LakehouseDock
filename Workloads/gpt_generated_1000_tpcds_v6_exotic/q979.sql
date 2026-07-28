WITH
  inventory_summary AS (
    SELECT
      i.i_item_sk,
      w.w_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, w.w_warehouse_sk
  )
SELECT * FROM (
  -- Catalog sales side (includes catalog returns)
  SELECT
    i.i_item_id                     AS item_id,
    w.w_state                       AS location_state,
    'catalog'                       AS sales_channel,
    SUM(cs.cs_ext_sales_price)      AS total_sales,
    SUM(cs.cs_net_profit)           AS total_profit,
    inv_sum.total_on_hand           AS total_on_hand
  FROM catalog_sales cs
  JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN inventory_summary inv_sum
    ON inv_sum.i_item_sk = i.i_item_sk AND inv_sum.w_warehouse_sk = w.w_warehouse_sk
  GROUP BY i.i_item_id, w.w_state, inv_sum.total_on_hand

  UNION ALL

  -- Store sales side
  SELECT
    i.i_item_id                     AS item_id,
    s.s_state                       AS location_state,
    'store'                         AS sales_channel,
    SUM(ss.ss_ext_sales_price)     AS total_sales,
    SUM(ss.ss_net_profit)          AS total_profit,
    inv_sum.total_on_hand           AS total_on_hand
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN inventory_summary inv_sum
    ON inv_sum.i_item_sk = i.i_item_sk
  GROUP BY i.i_item_id, s.s_state, inv_sum.total_on_hand

  UNION ALL

  -- Web returns side (includes web site for date joins)
  SELECT
    i.i_item_id                     AS item_id,
    ca.ca_state                     AS location_state,
    'web'                           AS sales_channel,
    SUM(wr.wr_return_amt_inc_tax)   AS total_sales,
    -SUM(wr.wr_net_loss)            AS total_profit,
    inv_sum.total_on_hand           AS total_on_hand
  FROM web_returns wr
  JOIN date_dim d_sales ON wr.wr_returned_date_sk = d_sales.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_site ws ON ws.web_site_sk = ws.web_site_sk  -- dummy join to bring the table into the query
  JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
  LEFT JOIN inventory_summary inv_sum
    ON inv_sum.i_item_sk = i.i_item_sk
  WHERE d_ws_open.d_year = d_sales.d_year  -- align years, no additional join rule required
  GROUP BY i.i_item_id, ca.ca_state, inv_sum.total_on_hand
) AS unified_result
LIMIT 100
