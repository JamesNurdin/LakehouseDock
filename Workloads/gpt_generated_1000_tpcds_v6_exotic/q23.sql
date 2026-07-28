WITH sales_returns AS (
    SELECT DISTINCT
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_ship_cost,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        cc.cc_name,
        cc.cc_state,
        w.w_state,
        w.w_gmt_offset,
        p.p_promo_name,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_quantity >= 70
      AND cs.cs_ext_ship_cost > 500
      AND w.w_gmt_offset = -6.00
)
SELECT
    cc_name,
    w_state,
    p_promo_name,
    r_reason_desc,
    SUM(cs_net_paid_inc_tax) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_quantity) AS avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS sales_rank_by_state
FROM sales_returns
GROUP BY cc_name, w_state, p_promo_name, r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
