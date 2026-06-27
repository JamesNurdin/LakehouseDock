WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_order_number
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_order_number
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COUNT(DISTINCT s.cs_bill_customer_sk) AS distinct_customers
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq, cc.cc_name, sm.sm_type, w.w_warehouse_name
ORDER BY d.d_year, d.d_month_seq, cc.cc_name, sm.sm_type, w.w_warehouse_name
