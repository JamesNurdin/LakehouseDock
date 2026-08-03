WITH high_rev_customers AS (
    SELECT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    WHERE sr.sr_reversed_charge > 300
),
high_loss_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 200
),
promo_active AS (
    SELECT p.p_promo_sk AS p_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    ws.ws_promo_sk IN (SELECT p_sk FROM promo_active)
    AND hd.hd_vehicle_count = 0
    AND ws.ws_net_paid_inc_ship BETWEEN 2000 AND 5000
    AND c.c_customer_sk IN (
        SELECT cust_sk FROM high_rev_customers
        INTERSECT
        SELECT cust_sk FROM high_loss_customers
    )
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    p.p_promo_name
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
