WITH store_agg AS (
    SELECT
        t.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS revenue_category
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY t.t_hour
)
SELECT
    'Store' AS channel,
    hour,
    total_net_paid,
    transaction_count,
    revenue_category
FROM store_agg
UNION ALL
SELECT
    'Web' AS channel,
    t.t_hour AS hour,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_count,
    CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS revenue_category
FROM web_sales ws
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_state = 'CA'
GROUP BY t.t_hour
ORDER BY channel, hour
LIMIT 100
