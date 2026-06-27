WITH
  store_agg AS (
    SELECT
      ca.ca_state,
      SUM(sr.sr_net_loss) AS store_net_loss,
      SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  web_return_agg AS (
    SELECT
      ca.ca_state,
      SUM(wr.wr_net_loss) AS web_net_loss,
      SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  web_sales_agg AS (
    SELECT
      ca.ca_state,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_quantity) AS web_quantity,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  )
SELECT
  COALESCE(s.ca_state, r.ca_state, w.ca_state) AS state,
  COALESCE(s.store_net_loss, 0)      AS store_net_loss,
  COALESCE(s.store_return_qty, 0)   AS store_return_qty,
  COALESCE(r.web_net_loss, 0)       AS web_net_loss,
  COALESCE(r.web_return_qty, 0)    AS web_return_qty,
  COALESCE(w.web_net_profit, 0)    AS web_net_profit,
  COALESCE(w.web_quantity, 0)      AS web_quantity,
  COALESCE(w.web_sales_amount, 0)  AS web_sales_amount
FROM store_agg s
FULL OUTER JOIN web_return_agg r
  ON s.ca_state = r.ca_state
FULL OUTER JOIN web_sales_agg w
  ON COALESCE(s.ca_state, r.ca_state) = w.ca_state
ORDER BY state
