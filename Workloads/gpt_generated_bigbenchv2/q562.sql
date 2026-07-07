WITH ordered_logs AS (
    SELECT
        wl_id,
        wl_customer_id,
        wl_webpage_name,
        CAST(wl_timestamp AS timestamp) AS wl_ts,
        row_number() OVER (PARTITION BY wl_customer_id ORDER BY CAST(wl_timestamp AS timestamp)) AS rn
    FROM web_logs
)
SELECT
    o1.wl_customer_id,
    o1.wl_webpage_name AS previous_page,
    o2.wl_webpage_name AS next_page,
    COUNT(*) AS transition_count
FROM ordered_logs o1
JOIN ordered_logs o2
    ON o1.wl_customer_id = o2.wl_customer_id
    AND o1.rn = o2.rn - 1
GROUP BY
    o1.wl_customer_id,
    o1.wl_webpage_name,
    o2.wl_webpage_name
ORDER BY transition_count DESC
LIMIT 100
