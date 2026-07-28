WITH store_sales_agg AS (
    SELECT
        'store' AS src,
        s.s_store_id AS id,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_zip LIKE '79%'
    GROUP BY s.s_store_id
),
web_sales_agg AS (
    SELECT
        'web' AS src,
        w.web_site_id AS id,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_state = 'CA'
    GROUP BY w.web_site_id
)
SELECT src, id, total_net_paid
FROM store_sales_agg
UNION ALL
SELECT src, id, total_net_paid
FROM web_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
