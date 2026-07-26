WITH daily_activity AS (
    SELECT
        d.d_date,
        COUNT(DISTINCT cc_open.cc_call_center_sk) AS centers_opened,
        COUNT(DISTINCT cc_close.cc_call_center_sk) AS centers_closed,
        COUNT(DISTINCT ws_open.web_site_sk) AS sites_opened,
        COUNT(DISTINCT ws_close.web_site_sk) AS sites_closed,
        COUNT(DISTINCT wp_create.wp_web_page_sk) AS pages_created,
        COUNT(DISTINCT wp_access.wp_web_page_sk) AS pages_accessed
    FROM date_dim d
    LEFT JOIN call_center cc_open ON cc_open.cc_open_date_sk = d.d_date_sk
    LEFT JOIN call_center cc_close ON cc_close.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_open ON ws_open.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_close ON ws_close.web_close_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_create ON wp_create.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access ON wp_access.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    d_date,
    centers_opened,
    centers_closed,
    sites_opened,
    sites_closed,
    pages_created,
    pages_accessed,
    (centers_opened + centers_closed + sites_opened + sites_closed + pages_created + pages_accessed) AS total_activity,
    RANK() OVER (ORDER BY (centers_opened + centers_closed + sites_opened + sites_closed + pages_created + pages_accessed) DESC) AS activity_rank,
    CASE
        WHEN (centers_opened + centers_closed + sites_opened + sites_closed + pages_created + pages_accessed) > 100 THEN 'High'
        ELSE 'Low'
    END AS activity_level
FROM daily_activity
WHERE (centers_opened + centers_closed + sites_opened + sites_closed + pages_created + pages_accessed) > 0
ORDER BY activity_rank
