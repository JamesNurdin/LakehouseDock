WITH
  base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_warehouse_sk,
      wh.w_warehouse_name,
      sm.sm_type,
      ws.ws_ship_mode_sk,
      ws.ws_net_paid,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ca.ca_state,
      ca.ca_country,
      ws.ws_ship_cdemo_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_sold_date_sk,
      sr.sr_return_amt,
      sr.sr_refunded_cash,
      ws.ws_web_site_sk,
      ws.ws_ship_date_sk,
      ws.ws_quantity
    FROM web_sales ws
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
      ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store_returns sr
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
      ws.ws_ship_cdemo_sk IN (1543645, 634525)
      AND wh.w_city = 'Fairview'
      AND sm.sm_carrier = 'UPS'
      AND wsite.web_state = 'CA'
      AND sr.sr_return_amt > 200
  ),
  high_returns AS (
    SELECT w_warehouse_name, sm_type, sr_return_amt, ws_net_profit
    FROM base
    WHERE sr_return_amt >= 500
  ),
  low_returns AS (
    SELECT w_warehouse_name, sm_type, sr_return_amt, ws_net_profit
    FROM base
    WHERE sr_return_amt < 500
  ),
  combined AS (
    SELECT * FROM high_returns
    UNION ALL
    SELECT * FROM low_returns
  ),
  agg AS (
    SELECT
      c.w_warehouse_name,
      c.sm_type,
      COUNT(*) AS txn_count,
      SUM(c.sr_return_amt) AS total_return_amt,
      SUM(c.ws_net_profit) AS total_net_profit,
      AVG(c.ws_net_profit) AS avg_net_profit
    FROM combined c
    GROUP BY c.w_warehouse_name, c.sm_type
  )
SELECT
  a.w_warehouse_name,
  a.sm_type,
  a.txn_count,
  a.total_return_amt,
  a.total_net_profit,
  a.avg_net_profit,
  (SELECT AVG(ws3.ws_net_profit) FROM web_sales ws3) AS overall_avg_profit,
  RANK() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_return_amt DESC) AS return_rank,
  SUM(a.total_return_amt) OVER (
    PARTITION BY a.w_warehouse_name
    ORDER BY a.sm_type
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_return_by_type
FROM agg a
ORDER BY a.total_return_amt DESC
LIMIT 100
