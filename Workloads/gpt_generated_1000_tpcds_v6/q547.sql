WITH sales_summary AS (
  SELECT
    d.d_year,
    sm.sm_type,
    ca_store.ca_state AS ca_state,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(wr.wr_net_loss) AS return_loss
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    AND sm.sm_type = 'OVERNIGHT'
    AND ca_store.ca_state = 'CA'
  GROUP BY GROUPING SETS (
    (d.d_year, sm.sm_type, ca_store.ca_state),
    (d.d_year, sm.sm_type),
    (d.d_year),
    ()
  )
)
SELECT
  d_year,
  sm_type,
  ca_state,
  store_profit,
  web_profit,
  return_loss,
  (store_profit + web_profit - return_loss) AS total_net
FROM sales_summary
WHERE (store_profit + web_profit - return_loss) > 0
ORDER BY d_year, sm_type, ca_state
