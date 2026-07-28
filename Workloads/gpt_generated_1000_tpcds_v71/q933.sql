WITH ws_enriched AS (
  SELECT
    ws.ws_order_number,
    ws.ws_warehouse_sk,
    ws.ws_bill_customer_sk,
    ws.ws_sold_time_sk,
    ws.ws_bill_addr_sk,
    ws.ws_ship_addr_sk,
    ws.ws_net_paid,
    ws.ws_net_profit,
    td.t_hour      AS sale_hour,
    ca_bill.ca_state AS billing_state,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_net_paid DESC) AS rn
  FROM tpcds.web_sales ws
  JOIN tpcds.time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk          -- join 1
  JOIN tpcds.customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk -- join 2
  JOIN tpcds.customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk -- join 3
  JOIN tpcds.warehouse wh1
    ON ws.ws_warehouse_sk = wh1.w_warehouse_sk    -- join 4
  JOIN tpcds.warehouse wh2
    ON ws.ws_warehouse_sk = wh2.w_warehouse_sk    -- join 5 (second alias)
  JOIN tpcds.time_dim td_extra
    ON ws.ws_sold_time_sk = td_extra.t_time_sk   -- join 6 (second time_dim alias)
),
sr_enriched AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_amt,
    sr.sr_customer_sk,
    td1.t_hour AS return_hour1,
    td2.t_hour AS return_hour2,
    ca1.ca_state AS return_state1,
    ca2.ca_state AS return_state2
  FROM tpcds.store_returns sr
  JOIN tpcds.time_dim td1
    ON sr.sr_return_time_sk = td1.t_time_sk       -- join 7
  JOIN tpcds.time_dim td2
    ON sr.sr_return_time_sk = td2.t_time_sk       -- join 8 (second alias)
  JOIN tpcds.customer_address ca1
    ON sr.sr_addr_sk = ca1.ca_address_sk          -- join 9
  JOIN tpcds.customer_address ca2
    ON sr.sr_addr_sk = ca2.ca_address_sk          -- join 10 (second alias)
)
SELECT
  wh.w_warehouse_name,
  we.billing_state,
  we.sale_hour,
  SUM(we.ws_net_paid)               AS total_sales,
  COUNT(DISTINCT we.ws_order_number) AS orders_cnt,
  COALESCE(SUM(se.sr_return_amt), 0) AS total_return_amount,
  COUNT(se.sr_ticket_number)         AS return_cnt,
  MAX(we.rn)                         AS max_row_num_per_warehouse
FROM ws_enriched we
JOIN tpcds.warehouse wh
  ON we.ws_warehouse_sk = wh.w_warehouse_sk            -- join 11 (outer join)
LEFT JOIN sr_enriched se
  ON we.ws_order_number = se.sr_ticket_number
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_customer_sk = we.ws_bill_customer_sk
      AND sr2.sr_return_amt > 5000
)                                                       -- anti‑join
GROUP BY wh.w_warehouse_name, we.billing_state, we.sale_hour
HAVING SUM(we.ws_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
