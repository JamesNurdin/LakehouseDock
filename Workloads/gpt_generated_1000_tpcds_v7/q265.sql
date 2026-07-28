WITH base AS (
  SELECT
    cc.cc_call_center_id,
    d.d_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_quantity_on_hand
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk IN (101410, 101420)
  LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  WHERE
    d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND t.t_second <= 5
    AND cr.cr_return_amount > 100
  GROUP BY
    cc.cc_call_center_id,
    d.d_date
  HAVING
    SUM(cr.cr_return_amount) > 500
)
SELECT
  cc_call_center_id,
  d_date,
  total_return_amount,
  total_return_qty,
  total_quantity_on_hand,
  ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_return_amount DESC) AS rn
FROM base
ORDER BY d_date, rn
LIMIT 100
