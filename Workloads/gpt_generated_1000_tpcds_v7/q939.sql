WITH order_metrics AS (
    SELECT
        s.cs_order_number,
        c.cc_call_center_id AS cc_id,
        w.w_warehouse_id AS warehouse_id,
        d.cd_gender AS gender,
        p.p_promo_name AS promo_name,
        SUM(s.cs_net_profit) AS order_net_profit,
        SUM(r.cr_return_amount) AS order_return_amount,
        COUNT(*) FILTER (WHERE s.cs_quantity > 0) AS sales_line_cnt,
        COUNT(r.cr_return_quantity) FILTER (WHERE r.cr_return_quantity > 0) AS return_line_cnt
    FROM catalog_sales s
    JOIN catalog_returns r
        ON r.cr_order_number = s.cs_order_number
    JOIN call_center c
        ON s.cs_call_center_sk = c.cc_call_center_sk
    JOIN warehouse w
        ON s.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON s.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics d
        ON s.cs_bill_cdemo_sk = d.cd_demo_sk
    WHERE c.cc_company IN (1, 2)
      AND c.cc_state = 'CA'
      AND w.w_state = 'TX'
      AND p.p_cost > 500
      AND s.cs_net_paid_inc_ship > 1000
      AND p.p_end_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY s.cs_order_number, c.cc_call_center_id, w.w_warehouse_id, d.cd_gender, p.p_promo_name
)
SELECT
    cc_id,
    warehouse_id,
    gender,
    promo_name,
    SUM(order_net_profit) AS total_net_profit,
    SUM(order_return_amount) AS total_return_amount,
    AVG(order_net_profit) AS avg_net_profit_per_order,
    COUNT(*) AS orders_cnt
FROM order_metrics
GROUP BY GROUPING SETS (
    (cc_id, warehouse_id, gender, promo_name),
    (cc_id, warehouse_id, gender),
    (cc_id, warehouse_id),
    (cc_id),
    ()
)
HAVING SUM(order_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
