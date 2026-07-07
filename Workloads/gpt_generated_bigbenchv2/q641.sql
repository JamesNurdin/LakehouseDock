WITH page_views AS (
    SELECT
        wl_webpage_name,
        DATE_TRUNC('day', DATE_PARSE(wl_timestamp, '%Y-%m-%d %H:%i:%s')) AS event_day,
        COUNT(*) AS view_count
    FROM web_logs
    WHERE wl_timestamp IS NOT NULL
    GROUP BY wl_webpage_name,
             DATE_TRUNC('day', DATE_PARSE(wl_timestamp, '%Y-%m-%d %H:%i:%s'))
)
SELECT
    w.wl_webpage_name,
    DATE_TRUNC('day', DATE_PARSE(w.wl_timestamp, '%Y-%m-%d %H:%i:%s')) AS event_day,
    COUNT(*) AS total_hits,
    pv.view_count
FROM web_logs w
JOIN page_views pv
    ON w.wl_webpage_name = pv.wl_webpage_name
   AND DATE_TRUNC('day', DATE_PARSE(w.wl_timestamp, '%Y-%m-%d %H:%i:%s')) = pv.event_day
WHERE w.wl_timestamp IS NOT NULL
GROUP BY w.wl_webpage_name,
         DATE_TRUNC('day', DATE_PARSE(w.wl_timestamp, '%Y-%m-%d %H:%i:%s')),
         pv.view_count
ORDER BY total_hits DESC
LIMIT 10
