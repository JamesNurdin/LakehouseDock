WITH logs_by_date AS (
    SELECT
        wl_webpage_name,
        date(cast(wl_timestamp AS timestamp)) AS view_date
    FROM web_logs
    WHERE wl_customer_id IS NOT NULL
)
SELECT
    wl_webpage_name,
    view_date,
    count(*) AS view_count
FROM logs_by_date
GROUP BY wl_webpage_name, view_date
ORDER BY view_date DESC, view_count DESC
LIMIT 100
