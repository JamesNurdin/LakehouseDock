WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        p.p_promo_name,
        w.w_warehouse_name,
        w.w_gmt_offset,
        c_bill.c_customer_id AS bill_customer_id,
        c_refund.c_customer_id AS refund_customer_id,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        CASE
            WHEN wr.wr_return_ship_cost > 500 THEN 'High'
            WHEN wr.wr_return_ship_cost > 200 THEN 'Medium'
            ELSE 'Low'
        END AS return_ship_cost_category
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    WHERE c_bill.c_birth_month IN (3, 5, 9, 12)
      AND c_refund.c_last_review_date >= 2452400
      AND w.w_gmt_offset = -5.00
      AND wr.wr_return_ship_cost > 100.00
),
warehouse_metrics AS (
    SELECT
        w_warehouse_name,
        SUM(ws_ext_sales_price) AS sales_amount,
        SUM(ws_net_profit) AS profit_amount,
        SUM(wr_return_amt) AS return_amount,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        AVG(CASE WHEN return_ship_cost_category = 'High' THEN 1 ELSE 0 END) AS high_return_ratio
    FROM sales_returns
    GROUP BY w_warehouse_name
    HAVING SUM(ws_ext_sales_price) > 1000
       AND COUNT(DISTINCT ws_order_number) >= 5
),
combined_metrics AS (
    SELECT w_warehouse_name,
           sales_amount AS metric,
           'sales' AS metric_type
    FROM warehouse_metrics
    UNION ALL
    SELECT w_warehouse_name,
           return_amount AS metric,
           'returns' AS metric_type
    FROM warehouse_metrics
)
SELECT
    cm.w_warehouse_name,
    cm.metric_type,
    cm.metric,
    wm.profit_amount,
    wm.order_cnt,
    wm.high_return_ratio,
    cm.metric - (SELECT AVG(metric) FROM combined_metrics) AS metric_vs_avg
FROM combined_metrics cm
JOIN warehouse_metrics wm ON cm.w_warehouse_name = wm.w_warehouse_name
WHERE cm.metric > 500
ORDER BY cm.metric DESC
LIMIT 100
