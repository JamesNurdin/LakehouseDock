WITH ws_join AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_ext_sales_price,
    ws.ws_coupon_amt,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    i.i_category,
    i.i_brand,
    ca.ca_state,
    sm.sm_contract,
    cd.cd_gender
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_ext_sales_price > 1000
    AND ws.ws_coupon_amt > 0
    AND i.i_current_price BETWEEN 10 AND 500
    AND ca.ca_state = 'CA'
),
cr_join AS (
  SELECT
    cr.cr_order_number,
    cr.cr_item_sk,
    cr.cr_return_amount,
    cr.cr_net_loss,
    i2.i_category AS cr_category,
    ca2.ca_state AS cr_state,
    sm2.sm_contract AS cr_contract,
    w2.w_warehouse_sq_ft,
    cd2.cd_gender AS cr_gender,
    cc.cc_call_center_id
  FROM catalog_returns cr
  JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
  JOIN customer_address ca2 ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
  JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
  JOIN customer_demographics cd2 ON cr.cr_refunded_cdemo_sk = cd2.cd_demo_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cr.cr_return_amount > 500
    AND cr.cr_net_loss > 0
    AND ca2.ca_state = 'CA'
    AND w2.w_warehouse_sq_ft > 800000
),
contract_chars AS (
  SELECT
    ws.ws_order_number,
    ch
  FROM ws_join ws
  CROSS JOIN UNNEST(split(ws.sm_contract, '')) AS t(ch)
)
SELECT
  ws.ws_order_number,
  ws.ws_item_sk,
  i.i_category,
  i.i_brand,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_ext_sales_price) AS avg_sales,
  COUNT(DISTINCT ws.ws_bill_cdemo_sk) AS distinct_customers,
  MIN(ws.ws_coupon_amt) AS min_coupon,
  MAX(ws.ws_coupon_amt) AS max_coupon,
  COUNT(DISTINCT cc.ch) AS distinct_contract_chars
FROM ws_join ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN contract_chars cc ON ws.ws_order_number = cc.ws_order_number
WHERE ws.ws_order_number IN (
    SELECT cr_order_number FROM cr_join
    INTERSECT
    SELECT ws_order_number FROM ws_join
)
GROUP BY ws.ws_order_number, ws.ws_item_sk, i.i_category, i.i_brand
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
