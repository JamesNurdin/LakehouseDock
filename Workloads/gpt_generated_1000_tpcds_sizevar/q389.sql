WITH
    ws_agg AS (
        SELECT
            d.d_year,
            sm.sm_type,
            SUM(ws.ws_net_profit) AS total_profit,
            SUM(ws.ws_quantity) AS total_qty,
            CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2020
        GROUP BY d.d_year, sm.sm_type
    ),
    sr_agg AS (
        SELECT
            d.d_year,
            r.r_reason_desc,
            SUM(sr.sr_net_loss) AS total_loss,
            SUM(sr.sr_return_quantity) AS total_qty,
            CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE d.d_year = 2020
        GROUP BY d.d_year, r.r_reason_desc
    )
SELECT
    ws_agg.d_year AS year,
    ws_agg.sm_type AS category,
    metric_name,
    metric_value,
    ws_agg.profit_flag AS flag
FROM ws_agg
CROSS JOIN UNNEST(
    ARRAY['profit', 'quantity'],
    ARRAY[ws_agg.total_profit, ws_agg.total_qty]
) AS u(metric_name, metric_value)
UNION ALL
SELECT
    sr_agg.d_year AS year,
    sr_agg.r_reason_desc AS category,
    metric_name,
    metric_value,
    sr_agg.loss_flag AS flag
FROM sr_agg
CROSS JOIN UNNEST(
    ARRAY['loss', 'quantity'],
    ARRAY[sr_agg.total_loss, sr_agg.total_qty]
) AS u(metric_name, metric_value)
ORDER BY year DESC, category, metric_name
LIMIT 100
