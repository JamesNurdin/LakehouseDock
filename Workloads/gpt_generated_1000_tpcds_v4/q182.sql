WITH return_sales AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_ext_ship_cost,
        cs.cs_coupon_amt,
        p.p_promo_name,
        r.r_reason_desc,
        cust_ref.c_birth_month AS refunded_birth_month,
        cust_ret.c_birth_month AS returning_birth_month,
        cust_bill.c_birth_month AS billing_birth_month,
        cust_ship.c_birth_month AS shipping_birth_month
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer cust_ret
        ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    WHERE cr.cr_warehouse_sk = 5
      AND cr.cr_return_amount > 100.00
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%defect%'
      AND cust_ref.c_birth_month = 3
)
SELECT
    rs.p_promo_name,
    rs.r_reason_desc,
    COUNT(DISTINCT rs.cr_order_number) AS order_cnt,
    SUM(rs.cr_return_amount) AS total_return_amount,
    AVG(rs.cs_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
    MIN(rs.cr_refunded_cash) AS min_refunded_cash,
    MAX(rs.cs_ext_ship_cost) AS max_ship_cost
FROM return_sales rs
GROUP BY rs.p_promo_name, rs.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
