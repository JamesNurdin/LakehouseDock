/*
Goal: Compare hourly financial impact of catalog returns versus web sales by ship mode, categorizing amounts as High or Low and presenting a distinct, ordered list of the combined results.
*/
WITH catalog_data AS (
    SELECT
        td.t_hour AS hour,
        sm.sm_type AS mode_type,
        'Return' AS metric_type,
        SUM(cr.cr_return_amt_inc_tax) AS total_amount,
        CASE WHEN SUM(cr.cr_return_amt_inc_tax) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amt_inc_tax IS NOT NULL
      AND td.t_hour BETWEEN 0 AND 23
    GROUP BY td.t_hour, sm.sm_type
),
websales_data AS (
    SELECT
        td.t_hour AS hour,
        sm.sm_type AS mode_type,
        'Sale' AS metric_type,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_sales_price IS NOT NULL
      AND td.t_hour BETWEEN 0 AND 23
    GROUP BY td.t_hour, sm.sm_type
)
SELECT DISTINCT
    hour,
    mode_type,
    metric_type,
    total_amount,
    amount_category
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM websales_data
) AS combined
ORDER BY hour, mode_type, metric_type
LIMIT 100
