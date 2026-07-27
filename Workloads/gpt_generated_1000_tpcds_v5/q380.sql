WITH joined_data AS (
  SELECT
    ca.ca_city,
    ca.ca_state,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_net_profit,
    sr.sr_return_amt,
    sr.sr_store_credit,
    sr.sr_hdemo_sk,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    wr.wr_net_loss,
    wr.wr_account_credit,
    w.w_warehouse_name
  FROM customer_address ca
  JOIN store_sales ss
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_sales ws
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
)
SELECT
  ca_city,
  ca_state,
  ss_ticket_number,
  ss_net_paid,
  sr_return_amt,
  ws_net_paid,
  wr_net_loss,
  w_warehouse_name,
  total_state_net_paid,
  RANK() OVER (PARTITION BY ca_state ORDER BY total_state_net_paid DESC) AS state_rank
FROM (
  SELECT
    ca_city,
    ca_state,
    ss_ticket_number,
    ss_net_paid,
    sr_return_amt,
    ws_net_paid,
    wr_net_loss,
    w_warehouse_name,
    SUM(ss_net_paid) OVER (PARTITION BY ca_state) AS total_state_net_paid
  FROM joined_data
  WHERE sr_store_credit > 10
    AND sr_hdemo_sk IN (1481, 734)
    AND ws_net_profit > 0
    AND wr_account_credit < 200
    AND ca_state = 'CA'
) sub
ORDER BY ca_state, state_rank
LIMIT 100
