WITH return_agg AS (
    SELECT
        'Return' AS metric,
        w.w_county AS county,
        SUM(cr.cr_return_amount) AS total_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_tax > 50
    GROUP BY w.w_county
),
websale_agg AS (
    SELECT
        'WebSale' AS metric,
        w.w_county AS county,
        SUM(ws.ws_net_profit) AS total_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_sales_price > 50
        AND ws_site.web_gmt_offset > 0
    GROUP BY w.w_county
)
SELECT metric, county, total_amount
FROM return_agg
UNION ALL
SELECT metric, county, total_amount
FROM websale_agg
ORDER BY county, metric
LIMIT 100
