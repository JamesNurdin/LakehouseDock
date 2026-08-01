WITH store_data AS (
  SELECT
    sr.sr_returned_date_sk,
    i_sr.i_item_sk,
    i_sr.i_brand,
    c.c_customer_sk,
    ca.ca_state,
    hd.hd_income_band_sk,
    r.r_reason_desc,
    inv.inv_quantity_on_hand,
    w.w_warehouse_name,
    sr.sr_return_amt_inc_tax,
    sr.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY i_sr.i_item_sk ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn_store
  FROM store_returns sr
  JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv
    ON i_sr.i_item_sk = inv.inv_item_sk
  JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
web_data AS (
  SELECT
    wr.wr_returned_date_sk,
    i_ws.i_item_sk,
    i_ws.i_brand,
    c_ref.c_customer_sk AS refunded_customer_sk,
    ca_ref.ca_state AS refunded_state,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    r.r_reason_desc,
    wr.wr_return_amt_inc_tax,
    wr.wr_net_loss,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    w2.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY i_ws.i_item_sk ORDER BY wr.wr_return_amt_inc_tax DESC) AS rn_web
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
  JOIN item i_ws
    ON ws.ws_item_sk = i_ws.i_item_sk
  JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN warehouse w2
    ON ws.ws_warehouse_sk = w2.w_warehouse_sk
),
combined AS (
  SELECT
    i_item_sk,
    i_brand,
    refunded_customer_sk AS c_customer_sk,
    refunded_state AS ca_state,
    refunded_income_band AS hd_income_band_sk,
    r_reason_desc,
    wr_return_amt_inc_tax AS return_amount,
    wr_net_loss AS net_loss,
    NULL AS inv_quantity_on_hand,
    w_warehouse_name,
    'web' AS source,
    rn_web AS rn
  FROM web_data
  UNION ALL
  SELECT
    i_item_sk,
    i_brand,
    c_customer_sk,
    ca_state,
    hd_income_band_sk,
    r_reason_desc,
    sr_return_amt_inc_tax AS return_amount,
    sr_net_loss AS net_loss,
    inv_quantity_on_hand,
    w_warehouse_name,
    'store' AS source,
    rn_store AS rn
  FROM store_data
)
SELECT
  i_item_sk,
  i_brand,
  SUM(return_amount) AS total_return_amount,
  SUM(net_loss) AS total_net_loss,
  COUNT(DISTINCT c_customer_sk) AS unique_customers,
  MAX(rn) AS max_row_number,
  CASE WHEN SUM(return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_level,
  (SELECT AVG(ws_quantity) FROM web_sales ws_sub WHERE ws_sub.ws_item_sk = combined.i_item_sk) AS avg_ws_quantity,
  COUNT(*) OVER (PARTITION BY i_brand) AS brand_item_count
FROM combined
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr_chk
  WHERE sr_chk.sr_item_sk = combined.i_item_sk
    AND sr_chk.sr_customer_sk = combined.c_customer_sk
    AND sr_chk.sr_return_amt_inc_tax > 2000
)
GROUP BY i_item_sk, i_brand
HAVING COUNT(*) > 1
ORDER BY total_return_amount DESC
LIMIT 100
