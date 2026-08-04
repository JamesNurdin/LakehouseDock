WITH sub_a AS (
   SELECT
       cr.cr_order_number AS order_key,
       SUM(cr.cr_return_amount) AS amount
   FROM catalog_returns cr
   JOIN catalog_sales cs
       ON cr.cr_order_number = cs.cs_order_number
   JOIN customer cust_refund
       ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
   JOIN household_demographics hd_refund
       ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
   JOIN reason r_ret
       ON cr.cr_reason_sk = r_ret.r_reason_sk
   JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer cust_bill
       ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   JOIN household_demographics hd_bill
       ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN store_returns sr
       ON sr.sr_customer_sk = cust_refund.c_customer_sk
   JOIN household_demographics hd_store
       ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
   JOIN reason r_store
       ON sr.sr_reason_sk = r_store.r_reason_sk
   GROUP BY cr.cr_order_number
),
sub_b AS (
   SELECT
       cs.cs_order_number AS order_key,
       SUM(cs.cs_ext_sales_price) AS amount
   FROM catalog_sales cs
   JOIN promotion p2
       ON cs.cs_promo_sk = p2.p_promo_sk
   JOIN customer cust_ship
       ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
   JOIN household_demographics hd_ship
       ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN store_returns sr
       ON sr.sr_customer_sk = cust_ship.c_customer_sk
   JOIN reason r2
       ON sr.sr_reason_sk = r2.r_reason_sk
   JOIN household_demographics hd_store2
       ON sr.sr_hdemo_sk = hd_store2.hd_demo_sk
   JOIN catalog_returns cr2
       ON cs.cs_order_number = cr2.cr_order_number
   JOIN reason r_cr2
       ON cr2.cr_reason_sk = r_cr2.r_reason_sk
   GROUP BY cs.cs_order_number
)
SELECT
    order_key,
    amount,
    LAG(amount) OVER (ORDER BY order_key) AS prev_amount
FROM (
    SELECT order_key, amount FROM sub_a
    INTERSECT
    SELECT order_key, amount FROM sub_b
) intersected
ORDER BY order_key
LIMIT 100
