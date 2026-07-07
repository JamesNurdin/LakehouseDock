WITH page_daily AS (
    SELECT
        wl_webpage_name,
        date(cast(wl_timestamp as timestamp)) AS view_date,
        count(*) AS daily_views,
        count(DISTINCT wl_customer_id) AS daily_unique_customers
    FROM web_logs
    GROUP BY wl_webpage_name, date(cast(wl_timestamp as timestamp))
)
SELECT
    wl.wl_webpage_name,
    date(cast(wl.wl_timestamp as timestamp)) AS view_date,
    COUNT(*) AS view_count,
    COUNT(DISTINCT wl.wl_customer_id) AS unique_customers,
    pd.daily_views,
    pd.daily_unique_customers
FROM web_logs wl
JOIN page_daily pd
    ON wl.wl_webpage_name = pd.wl_webpage_name
    AND date(cast(wl.wl_timestamp as timestamp)) = pd.view_date
WHERE date(cast(wl.wl_timestamp as timestamp)) >= DATE '2023-01-01'
  AND date(cast(wl.wl_timestamp as timestamp)) < DATE '2023-02-01'
GROUP BY
    wl.wl_webpage_name,
    date(cast(wl.wl_timestamp as timestamp)),
    pd.daily_views,
    pd.daily_unique_customers
ORDER BY view_date DESC, view_count DESC
