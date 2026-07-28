WITH sales_metrics AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promo_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
),
return_metrics AS (
    SELECT
        c.c_customer_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
)
SELECT
    sm.c_customer_id,
    'sales' AS metric_type,
    sm.total_sales AS metric_value
FROM sales_metrics sm

UNION ALL

SELECT
    rm.c_customer_id,
    'returns' AS metric_type,
    rm.total_return_amount AS metric_value
FROM return_metrics rm

ORDER BY metric_value DESC
LIMIT 100
