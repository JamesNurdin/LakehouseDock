WITH joined_data AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        sm.sm_type,
        r.r_reason_desc,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        ca_refund.ca_state AS refund_state,
        sr.sr_return_amt,
        s.s_store_id,
        s.s_state AS store_state,
        ca_store.ca_state AS store_address_state
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca_store
        ON sr.sr_addr_sk = ca_store.ca_address_sk
)
SELECT
    c_customer_id,
    s_store_id,
    cr_return_amount,
    sr_return_amt,
    sm_type,
    r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY cr_return_amount DESC) AS rn,
    SUM(cr_return_amount + sr_return_amt) OVER (PARTITION BY s_store_id) AS store_total_return_amount
FROM joined_data
WHERE cr_return_quantity > 1
  AND cr_return_amount > 50
  AND cs_quantity >= 2
  AND cs_net_paid_inc_ship_tax > 1000
  AND sm_type = 'AIR'
  AND store_state = 'CA'
ORDER BY store_total_return_amount DESC, rn
LIMIT 100
