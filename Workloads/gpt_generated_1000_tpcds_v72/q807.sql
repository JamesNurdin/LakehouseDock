WITH store_sales_agg AS (
    SELECT
        s.s_state AS state,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        s.s_state
),
web_sales_agg AS (
    SELECT
        ws_site.web_state AS state,
        'web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        ws_site.web_state
)
SELECT * FROM store_sales_agg
UNION ALL
SELECT * FROM web_sales_agg
LIMIT 100
