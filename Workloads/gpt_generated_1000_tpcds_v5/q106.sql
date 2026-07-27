WITH
    open_sites AS (
        SELECT
            ws.web_site_id,
            d.d_quarter_name AS quarter,
            'OPEN' AS event_type,
            CASE WHEN ws.web_state = 'NM' THEN 'Southwest' ELSE 'Other' END AS region_group
        FROM
            web_site ws
            JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE
            ws.web_open_date_sk IS NOT NULL
            AND d.d_year >= 2000
    ),
    close_sites AS (
        SELECT
            ws.web_site_id,
            d.d_quarter_name AS quarter,
            'CLOSE' AS event_type,
            CASE WHEN ws.web_state = 'NM' THEN 'Southwest' ELSE 'Other' END AS region_group
        FROM
            web_site ws
            JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
        WHERE
            ws.web_close_date_sk IS NOT NULL
            AND d.d_year >= 2000
    ),
    combined AS (
        SELECT * FROM open_sites
        UNION ALL
        SELECT * FROM close_sites
    )
SELECT
    quarter,
    event_type,
    region_group,
    COUNT(DISTINCT web_site_id) AS site_count
FROM
    combined
GROUP BY
    quarter,
    event_type,
    region_group
ORDER BY
    quarter,
    event_type
LIMIT 100
