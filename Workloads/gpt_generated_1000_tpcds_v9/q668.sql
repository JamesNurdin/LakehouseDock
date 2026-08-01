WITH date_info AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= DATE '2001-01-01' AND d_date < DATE '2002-01-01'
)
SELECT
    combined.sales_date,
    combined.channel,
    combined.total_net_paid,
    combined.revenue_category
FROM (
    SELECT
        di.d_date AS sales_date,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'high' ELSE 'low' END AS revenue_category
    FROM store_sales ss
    JOIN date_info di ON ss.ss_sold_date_sk = di.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_quantity > 0
    GROUP BY di.d_date
    UNION ALL
    SELECT
        di.d_date AS sales_date,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'high' ELSE 'low' END AS revenue_category
    FROM web_sales ws
    JOIN date_info di ON ws.ws_sold_date_sk = di.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 0
    GROUP BY di.d_date
) AS combined
ORDER BY combined.total_net_paid DESC
LIMIT 100
