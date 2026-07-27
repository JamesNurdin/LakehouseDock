WITH returned_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity >= 1
      AND cr.cr_fee < 500
)
SELECT
    d_ret.d_date AS return_date,
    cc.cc_name AS call_center_name,
    cust_ref.c_first_name || ' ' || cust_ref.c_last_name AS refunded_customer_name,
    cust_ret.c_first_name || ' ' || cust_ret.c_last_name AS returning_customer_name,
    rd.cr_return_amount,
    rd.cr_return_tax,
    rd.cr_return_ship_cost,
    rd.cr_net_loss,
    CASE
        WHEN rd.cr_return_amount > 2000 THEN 'HIGH'
        WHEN rd.cr_return_amount > 1500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY rd.cr_return_amount DESC) AS rn_return_amount,
    RANK() OVER (PARTITION BY d_ret.d_year ORDER BY rd.cr_net_loss ASC) AS rank_net_loss_year
FROM returned_data rd
JOIN date_dim d_ret
  ON rd.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
  ON rd.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer cust_ref
  ON rd.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer cust_ret
  ON rd.cr_returning_customer_sk = cust_ret.c_customer_sk
LEFT JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cc.cc_state = 'CA'
  AND d_ret.d_year = 2002
  AND (s.s_state = 'CA' OR s.s_state IS NULL)
ORDER BY rd.cr_return_amount DESC, rn_return_amount
LIMIT 100
