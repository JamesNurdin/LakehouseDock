WITH sales_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    cc.cc_name,
    cp.cp_catalog_number,
    cp.cp_type
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  WHERE cs.cs_quantity >= 1
    AND cs.cs_quantity <= 10
    AND cs.cs_ext_sales_price > 100.00
    AND cs.cs_net_profit BETWEEN -50.00 AND 500.00
    AND cc.cc_company IN (1, 3, 5)
    AND cp.cp_catalog_number IN (7, 13, 19)
),

returns_data AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_returned_date_sk,
    sr.sr_return_amt,
    sr.sr_refunded_cash,
    ca_store.ca_state AS return_state,
    sr.sr_return_quantity
  FROM store_returns sr
  JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
  WHERE sr.sr_return_amt > 50.00
    AND sr.sr_refunded_cash < 1000.00
    AND ca_store.ca_state IN ('TX', 'CA', 'NY')
    AND sr.sr_return_quantity BETWEEN 1 AND 5
),

web_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ca_web_bill.ca_state AS web_bill_state,
    ca_web_ship.ca_state AS web_ship_state
  FROM web_sales ws
  JOIN customer_address ca_web_bill ON ws.ws_bill_addr_sk = ca_web_bill.ca_address_sk
  JOIN customer_address ca_web_ship ON ws.ws_ship_addr_sk = ca_web_ship.ca_address_sk
  WHERE ws.ws_quantity >= 1
    AND ws.ws_ext_sales_price > 200.00
    AND ws.ws_net_profit > 0
    AND ca_web_bill.ca_state NOT IN ('FL', 'NV')
    AND ca_web_ship.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 2451000 AND 2453000
)
SELECT
  sd.cc_name,
  sd.cp_type,
  sd.bill_state,
  sd.ship_state,
  COUNT(DISTINCT sd.cs_order_number) AS distinct_orders,
  SUM(sd.cs_ext_sales_price) AS total_sales,
  AVG(sd.cs_quantity) AS avg_quantity,
  MIN(sd.cs_net_profit) AS min_profit,
  MAX(sd.cs_net_profit) AS max_profit,
  COUNT(rd.sr_ticket_number) AS total_returns,
  SUM(rd.sr_return_amt) AS total_return_amount,
  SUM(wd.ws_ext_sales_price) AS total_web_sales,
  ROW_NUMBER() OVER (PARTITION BY sd.cc_name ORDER BY SUM(sd.cs_ext_sales_price) DESC) AS sales_rank
FROM sales_data sd
LEFT JOIN returns_data rd ON rd.sr_return_quantity = sd.cs_quantity
  AND rd.return_state = sd.ship_state
LEFT JOIN web_data wd ON wd.ws_order_number = sd.cs_order_number
  AND wd.web_bill_state = sd.bill_state
WHERE sd.cs_sold_date_sk BETWEEN 2451000 AND 2452000
GROUP BY
  sd.cc_name,
  sd.cp_type,
  sd.bill_state,
  sd.ship_state
ORDER BY total_sales DESC
LIMIT 100
