-- Net profit and return analysis per ship mode and month (year 2001)
WITH sales_agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sales.d_year = 2001
    GROUP BY d_sales.d_year, d_sales.d_month_seq, sm.sm_ship_mode_id, sm.sm_type
),
returns_agg AS (
    SELECT
        d_return.d_year,
        d_return.d_month_seq,
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_net_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_return.d_year = 2001
    GROUP BY d_return.d_year, d_return.d_month_seq, sm.sm_ship_mode_id, sm.sm_type
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.sm_ship_mode_id,
    s.sm_type,
    s.orders,
    s.total_quantity,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
    CASE WHEN s.total_quantity > 0 THEN COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity ELSE NULL END AS return_rate,
    s.total_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.sm_ship_mode_id = r.sm_ship_mode_id
ORDER BY s.d_year, s.d_month_seq, s.sm_ship_mode_id
