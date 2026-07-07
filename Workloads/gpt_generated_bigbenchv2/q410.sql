WITH first_visit AS (
    SELECT
        wl_customer_id,
        min(cast(wl_timestamp AS timestamp)) AS first_visit_ts
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT
    wl.wl_customer_id,
    COUNT(*) AS total_logs,
    COUNT(DISTINCT wl.wl_webpage_name) AS distinct_pages,
    AVG(date_diff('second', fv.first_visit_ts, cast(wl.wl_timestamp AS timestamp))) AS avg_seconds_since_first
FROM web_logs wl
JOIN first_visit fv
    ON wl.wl_customer_id = fv.wl_customer_id
WHERE cast(wl.wl_timestamp AS timestamp) >= date_add('day', -30, current_timestamp)
GROUP BY wl.wl_customer_id
ORDER BY total_logs DESC
LIMIT 100
