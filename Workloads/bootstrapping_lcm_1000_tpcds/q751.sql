WITH store_agg AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed,
        SUM(s.s_floor_space) AS total_store_floor_space,
        AVG(s.s_tax_percentage) AS avg_store_tax_percentage
    FROM
        store s
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_weekend
),
call_center_closed_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT cc.cc_call_center_sk) AS call_centers_closed
    FROM
        call_center cc
        JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk
),
call_center_open_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT cc.cc_call_center_sk) AS call_centers_opened
    FROM
        call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk
),
web_page_created_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created
    FROM
        web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk
),
web_page_accessed_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_accessed
    FROM
        web_page wp
        JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk
)
SELECT
    d.d_date,
    d.d_day_name,
    d.d_weekend,
    COALESCE(sa.stores_closed, 0) AS stores_closed,
    COALESCE(sa.total_store_floor_space, 0) AS total_store_floor_space,
    COALESCE(sa.avg_store_tax_percentage, 0) AS avg_store_tax_percentage,
    COALESCE(ccc.call_centers_closed, 0) AS call_centers_closed,
    COALESCE(cco.call_centers_opened, 0) AS call_centers_opened,
    COALESCE(wpc.web_pages_created, 0) AS web_pages_created,
    COALESCE(wpa.web_pages_accessed, 0) AS web_pages_accessed,
    ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS rank_by_date
FROM
    date_dim d
    LEFT JOIN store_agg sa ON sa.d_date_sk = d.d_date_sk
    LEFT JOIN call_center_closed_agg ccc ON ccc.d_date_sk = d.d_date_sk
    LEFT JOIN call_center_open_agg cco ON cco.d_date_sk = d.d_date_sk
    LEFT JOIN web_page_created_agg wpc ON wpc.d_date_sk = d.d_date_sk
    LEFT JOIN web_page_accessed_agg wpa ON wpa.d_date_sk = d.d_date_sk
WHERE
    d.d_date BETWEEN DATE '2020-01-01' AND DATE '2022-12-31'
ORDER BY
    d.d_date DESC
LIMIT 100
