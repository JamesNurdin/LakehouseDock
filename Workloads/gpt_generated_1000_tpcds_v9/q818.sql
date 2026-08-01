WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_bill_addr_sk,
    ws.ws_ship_mode_sk,
    ws.ws_net_paid,
    ws.ws_sold_date_sk,
    i.i_brand,
    i.i_manager_id,
    sm.sm_contract,
    ca.ca_state,
    ws.ws_web_site_sk,
    ws.ws_ship_date_sk
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE i.i_manager_id IN (63, 18)
)
SELECT
  'HVDFCcQ' AS contract_group,
  fs.i_brand,
  SUM(fs.ws_net_paid) AS total_net_paid,
  COUNT(DISTINCT fs.ws_order_number) AS distinct_orders
FROM filtered_sales fs
WHERE fs.sm_contract = 'HVDFCcQ'
  AND fs.ca_state = 'CA'
GROUP BY fs.i_brand
UNION ALL
SELECT
  'qENFQ' AS contract_group,
  fs.i_brand,
  SUM(fs.ws_net_paid) AS total_net_paid,
  COUNT(DISTINCT fs.ws_order_number) AS distinct_orders
FROM filtered_sales fs
WHERE fs.sm_contract = 'qENFQ'
  AND fs.ca_state = 'TX'
GROUP BY fs.i_brand
ORDER BY contract_group, total_net_paid DESC
