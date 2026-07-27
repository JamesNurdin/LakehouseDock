WITH base AS (
  SELECT
    d.d_date,
    cc.cc_name,
    cc.cc_state,
    r.r_reason_desc,
    cr.cr_return_amount,
    ws.ws_net_profit,
    i.inv_quantity_on_hand,
    SUM(cr.cr_return_amount) OVER (PARTITION BY cc.cc_call_center_sk, r.r_reason_sk) AS sum_return_by_cc_reason,
    RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS profit_rank
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = cr.cr_item_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = ws.ws_item_sk
  WHERE d.d_year = 1904
    AND cc.cc_state = 'CA'
    AND r.r_reason_desc LIKE '%product%'
    AND ws.ws_net_profit > 0
    AND d.d_month_seq BETWEEN 1200 AND 1300
)
SELECT
  d_date,
  cc_name,
  cc_state,
  r_reason_desc,
  cr_return_amount,
  ws_net_profit,
  COALESCE(inv_quantity_on_hand, 0) AS inventory_qty,
  sum_return_by_cc_reason,
  profit_rank
FROM base
ORDER BY profit_rank, d_date
LIMIT 100
