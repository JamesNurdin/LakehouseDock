WITH store_sales_by_state AS (
    SELECT
        s.s_state AS state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'store' AS channel
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_state
),
web_sales_by_state AS (
    SELECT
        ws_site.web_state AS state,
        SUM(ws.ws_net_paid) AS total_net_paid,
        'web' AS channel
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2002
    GROUP BY ws_site.web_state
)
SELECT state, total_net_paid, channel FROM store_sales_by_state
UNION ALL
SELECT state, total_net_paid, channel FROM web_sales_by_state
