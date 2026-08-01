WITH profit_metrics AS (
    SELECT
        ws.ws_web_site_sk,
        s.web_name,
        SUM(ws.ws_net_profit) AS metric_value,
        'profit' AS metric_type
    FROM web_sales ws
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE ws.ws_ext_discount_amt > 1000
    GROUP BY ws.ws_web_site_sk, s.web_name
    HAVING SUM(ws.ws_net_profit) > 5000
),

discount_metrics AS (
    SELECT
        ws.ws_web_site_sk,
        s.web_name,
        AVG(ws.ws_ext_discount_amt) AS metric_value,
        'avg_discount' AS metric_type
    FROM web_sales ws
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE ws.ws_quantity >= 25
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
            AND ws2.ws_quantity > 80
      )
    GROUP BY ws.ws_web_site_sk, s.web_name
    HAVING AVG(ws.ws_ext_discount_amt) > 2000
),

combined_metrics AS (
    SELECT ws_web_site_sk, web_name, metric_value, metric_type FROM profit_metrics
    UNION ALL
    SELECT ws_web_site_sk, web_name, metric_value, metric_type FROM discount_metrics
)
SELECT
    metric_type,
    web_name,
    metric_value,
    RANK() OVER (PARTITION BY metric_type ORDER BY metric_value DESC) AS metric_rank,
    (SELECT CURRENT_DATE) AS query_date
FROM combined_metrics
ORDER BY metric_type, metric_rank
