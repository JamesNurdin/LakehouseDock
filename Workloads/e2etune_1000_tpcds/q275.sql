WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 7
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY sm.sm_ship_mode_id, t.t_hour
),
returns_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        t.t_hour AS hour_of_day,
        SUM(cr.cr_net_loss) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_class = 'large'
      AND cc.cc_manager = 'Bob Belcher'
      AND c.c_birth_month = 7
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY sm.sm_ship_mode_id, t.t_hour
)
SELECT
    s.ship_mode_id,
    s.hour_of_day,
    s.total_sales,
    COALESCE(r.total_returns, CAST(0 AS decimal(7,2))) AS total_returns,
    (s.total_sales - COALESCE(r.total_returns, CAST(0 AS decimal(7,2)))) AS net_profit,
    s.sales_orders,
    COALESCE(r.return_orders, 0) AS return_orders
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ship_mode_id = r.ship_mode_id
   AND s.hour_of_day = r.hour_of_day
ORDER BY net_profit DESC
LIMIT 20
