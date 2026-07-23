WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cc.cc_name AS call_center_name,
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_zip,
        p.p_promo_name,
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN web_returns wr ON cust.c_customer_sk = wr.wr_refunded_customer_sk
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_coupon_amt < 2000
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    bs.cs_order_number,
    bs.cs_sold_date_sk,
    bs.cs_net_paid_inc_ship,
    bs.cs_net_profit,
    bs.call_center_name,
    bs.w_warehouse_name,
    bs.w_state,
    bs.w_zip,
    bs.p_promo_name,
    bs.c_first_name,
    bs.c_last_name,
    bs.cr_return_amount,
    bs.wr_return_amt,
    i.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY bs.warehouse_sk ORDER BY bs.cs_net_paid_inc_ship DESC) AS warehouse_sales_rank
FROM base_sales bs
JOIN inventory i ON i.inv_warehouse_sk = bs.warehouse_sk
WHERE i.inv_quantity_on_hand > 500
ORDER BY bs.cs_net_paid_inc_ship DESC
LIMIT 100
