WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_sold_date_sk,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        sm.sm_type AS ship_mode_type,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
)
SELECT
    s.i_category,
    s.d_year,
    s.d_month_seq,
    s.ship_mode_type,
    s.call_center_name,
    s.warehouse_name,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(s.cs_net_paid) AS total_sales_net_paid,
    SUM(s.cs_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT s.cs_order_number) AS distinct_sales_orders,
    SUM(r.cr_return_quantity) AS total_quantity_returned,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_return_net_loss,
    AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(r.cr_order_number) AS distinct_return_orders
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
GROUP BY
    s.i_category,
    s.d_year,
    s.d_month_seq,
    s.ship_mode_type,
    s.call_center_name,
    s.warehouse_name
ORDER BY
    total_sales_net_profit DESC
LIMIT 100
