WITH return_metrics AS (
    SELECT
        r.r_reason_desc AS category,
        'NetLoss' AS metric_name,
        SUM(cr.cr_net_loss) AS metric_value,
        t.t_meal_time AS meal_time
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE r.r_reason_id = 'AAAAAAAAJAAAAAAA'
      AND t.t_meal_time = 'dinner'
    GROUP BY r.r_reason_desc, t.t_meal_time
),
web_sales_metrics AS (
    SELECT
        CAST(ws.ws_web_site_sk AS VARCHAR) AS category,
        'NetPaid' AS metric_name,
        SUM(ws.ws_net_paid_inc_ship) AS metric_value,
        t.t_meal_time AS meal_time
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_web_site_sk IN (52, 44)
      AND t.t_meal_time = 'lunch'
    GROUP BY ws.ws_web_site_sk, t.t_meal_time
)
SELECT category,
       metric_name,
       metric_value,
       meal_time
FROM return_metrics
UNION
SELECT category,
       metric_name,
       metric_value,
       meal_time
FROM web_sales_metrics
ORDER BY category,
         metric_name,
         metric_value DESC
LIMIT 100
