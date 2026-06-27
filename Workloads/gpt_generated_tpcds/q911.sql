WITH cs_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        cd.d_year,
        sum(cs.cs_net_paid) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim cd ON cs.cs_sold_date_sk = cd.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, cd.d_year
),
cr_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        rd.d_year,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, rd.d_year
),
ws_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        wd.d_year,
        sum(ws.ws_net_paid) AS total_web_sales,
        sum(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, wd.d_year
)
SELECT
    cs.sm_ship_mode_id,
    cs.d_year,
    cs.total_sales,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    (cs.total_profit + COALESCE(ws.total_web_profit, 0) - COALESCE(cr.total_return_loss, 0)) AS net_combined_profit
FROM cs_agg cs
LEFT JOIN cr_agg cr
    ON cs.sm_ship_mode_id = cr.sm_ship_mode_id
    AND cs.d_year = cr.d_year
LEFT JOIN ws_agg ws
    ON cs.sm_ship_mode_id = ws.sm_ship_mode_id
    AND cs.d_year = ws.d_year
ORDER BY cs.sm_ship_mode_id, cs.d_year
