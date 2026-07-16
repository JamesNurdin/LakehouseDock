WITH sales_returns AS (
    SELECT
        w.w_city AS warehouse_city,
        t.t_hour AS hour_of_day,
        r.r_reason_desc AS return_reason,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        hd.hd_vehicle_count,
        wr.wr_return_amt_inc_tax,
        CASE WHEN wr.wr_order_number IS NOT NULL THEN 1 ELSE 0 END AS is_return
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc = 'Customer Not Satisfied')
),
aggregated AS (
    SELECT
        warehouse_city,
        hour_of_day,
        return_reason,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales_net_paid,
        SUM(ws_ext_discount_amt) AS total_sales_discount,
        SUM(is_return) AS total_returns,
        SUM(COALESCE(wr_return_amt_inc_tax, 0)) AS total_return_amount,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        (SUM(ws_net_paid) - SUM(COALESCE(wr_return_amt_inc_tax, 0))) AS net_profit_after_returns
    FROM sales_returns
    GROUP BY warehouse_city, hour_of_day, return_reason
)
SELECT
    warehouse_city,
    hour_of_day,
    return_reason,
    total_orders,
    total_sales_net_paid,
    total_sales_discount,
    total_returns,
    total_return_amount,
    avg_vehicle_count,
    net_profit_after_returns,
    RANK() OVER (PARTITION BY warehouse_city ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM aggregated
ORDER BY total_sales_net_paid DESC
LIMIT 100
