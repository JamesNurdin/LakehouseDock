WITH sales_agg AS ( 
    SELECT 
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
),
returns_agg AS ( 
    SELECT 
        cr.cr_order_number,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
)
SELECT 
    cc.cc_name AS call_center_name,
    r.r_reason_desc AS return_reason,
    sm.sm_type AS ship_mode_type,
    td_sold.t_hour AS sold_hour,
    COUNT(DISTINCT sa.cs_order_number) AS num_sales_orders,
    SUM(sa.cs_ext_sales_price) AS total_sales_amount,
    SUM(sa.cs_net_profit) AS total_sales_profit,
    COUNT(DISTINCT ra.cr_order_number) AS num_return_orders,
    COALESCE(SUM(ra.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(ra.cr_net_loss), 0) AS total_return_loss
FROM sales_agg sa
JOIN returns_agg ra 
    ON ra.cr_order_number = sa.cs_order_number
   AND ra.cr_item_sk = sa.cs_item_sk
JOIN call_center cc 
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN call_center rc_cc 
    ON ra.cr_call_center_sk = rc_cc.cc_call_center_sk
JOIN ship_mode sm 
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN ship_mode rc_sm 
    ON ra.cr_ship_mode_sk = rc_sm.sm_ship_mode_sk
JOIN time_dim td_sold 
    ON sa.cs_sold_time_sk = td_sold.t_time_sk
JOIN time_dim td_return 
    ON ra.cr_returned_time_sk = td_return.t_time_sk
JOIN reason r 
    ON ra.cr_reason_sk = r.r_reason_sk
JOIN customer bill_cust 
    ON sa.cs_bill_customer_sk = bill_cust.c_customer_sk
JOIN customer ship_cust 
    ON sa.cs_ship_customer_sk = ship_cust.c_customer_sk
JOIN customer refunded_cust 
    ON ra.cr_refunded_customer_sk = refunded_cust.c_customer_sk
JOIN customer returning_cust 
    ON ra.cr_returning_customer_sk = returning_cust.c_customer_sk
WHERE EXISTS ( 
    SELECT 1
    FROM customer c2
    WHERE c2.c_customer_sk = bill_cust.c_customer_sk
      AND c2.c_preferred_cust_flag = 'Y'
)
GROUP BY 
    cc.cc_name,
    r.r_reason_desc,
    sm.sm_type,
    td_sold.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
