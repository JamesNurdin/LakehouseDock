WITH daily_counts AS (
    SELECT
        date(cast(wl_timestamp AS timestamp)) AS log_date,
        count(*) AS total_logs
    FROM web_logs
    GROUP BY date(cast(wl_timestamp AS timestamp))
),
page_daily_counts AS (
    SELECT
        wl_webpage_name,
        date(cast(wl_timestamp AS timestamp)) AS log_date,
        count(*) AS page_logs,
        count(DISTINCT wl_customer_id) AS unique_customers
    FROM web_logs
    GROUP BY wl_webpage_name, date(cast(wl_timestamp AS timestamp))
)
SELECT
    pdc.wl_webpage_name,
    pdc.log_date,
    pdc.page_logs,
    pdc.unique_customers,
    dc.total_logs,
    (pdc.page_logs * 100.0) / dc.total_logs AS page_share_pct
FROM page_daily_counts pdc
JOIN daily_counts dc
    ON pdc.log_date = dc.log_date
ORDER BY pdc.log_date DESC, pdc.page_logs DESC
LIMIT 100
