WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_market_manager = 'Gary Colburn'
      AND cc.cc_county = 'Gogebic County'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_coupon_amt = 0.00
),
returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defective%'
      AND sr.sr_return_amt > 100
      AND sr.sr_return_ship_cost < 100
)
SELECT
    cc.cc_name,
    sm.sm_type,
    p.p_promo_name,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    SUM(s.cs_net_paid) AS total_net_paid,
    AVG(s.cs_coupon_amt) AS avg_coupon,
    MIN(r.sr_return_amt) AS min_return_amt,
    MAX(r.sr_return_ship_cost) AS max_return_ship_cost
FROM sales s
JOIN customer c_bill ON s.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON s.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN returns r ON r.sr_customer_sk = c_bill.c_customer_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY GROUPING SETS (
    (cc.cc_name, sm.sm_type, p.p_promo_name),
    (cc.cc_name, sm.sm_type),
    (cc.cc_name),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
