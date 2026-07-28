WITH ws_agg AS (
  SELECT
    ws_item_sk,
    ws_web_site_sk,
    ws_ship_mode_sk,
    ws_warehouse_sk,
    SUM(ws_ext_sales_price) AS total_ext_sales,
    SUM(ws_quantity) AS total_qty
  FROM tpcds.web_sales
  GROUP BY
    ws_item_sk,
    ws_web_site_sk,
    ws_ship_mode_sk,
    ws_warehouse_sk
)

SELECT
  s.s_store_name,
  i.i_product_name,
  ws_agg.total_ext_sales,
  ws_agg.total_qty,
  wr.wr_return_amt,
  (
    SELECT AVG(sr2.sr_return_amt)
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_item_sk = i.i_item_sk
  ) AS avg_store_return_amt,
  RANK() OVER (PARTITION BY s.s_state ORDER BY ws_agg.total_ext_sales DESC) AS sales_rank,
  CASE
    WHEN ws_agg.total_ext_sales > 50000 THEN 'HIGH'
    WHEN ws_agg.total_ext_sales > 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS sales_category
FROM ws_agg
JOIN tpcds.item i
  ON ws_agg.ws_item_sk = i.i_item_sk
JOIN tpcds.web_site ws
  ON ws_agg.ws_web_site_sk = ws.web_site_sk
JOIN tpcds.ship_mode sm
  ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse wh
  ON ws_agg.ws_warehouse_sk = wh.w_warehouse_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN tpcds.customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN tpcds.customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN tpcds.web_sales ws_raw
  ON ws_raw.ws_item_sk = i.i_item_sk
  AND ws_raw.ws_order_number = wr.wr_order_number
JOIN tpcds.reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN tpcds.customer_demographics cd_wr_ref
  ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
JOIN tpcds.customer_address ca_wr_ref
  ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN tpcds.customer_demographics cd_wr_ret
  ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
JOIN tpcds.customer_address ca_wr_ret
  ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
WHERE
  i.i_current_price > 100
  AND cd_sr.cd_marital_status = 'M'
  AND ca_sr.ca_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND s.s_state = 'CA'
  AND wr.wr_return_amt > 200
ORDER BY
  sales_rank,
  s.s_store_name
