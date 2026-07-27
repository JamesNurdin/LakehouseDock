WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        td.t_hour,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND ws.ws_ext_sales_price > 1000
        AND EXISTS (
            SELECT 1
            FROM web_site ws2
            WHERE ws2.web_site_sk = ws.ws_web_site_sk
              AND ws2.web_manager LIKE '%Davis%'
        )
)
SELECT
    site.web_name,
    agg.t_hour,
    SUM(agg.total_sales) AS total_sales,
    AVG(agg.avg_profit) AS avg_profit_per_order
FROM (
    SELECT
        ws_web_site_sk,
        t_hour,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM sales_agg
    GROUP BY ws_web_site_sk, t_hour
) agg
JOIN web_site site
    ON agg.ws_web_site_sk = site.web_site_sk
WHERE site.web_state = 'CA'
GROUP BY site.web_name, agg.t_hour
HAVING SUM(agg.total_sales) > 5000
ORDER BY total_sales DESC
LIMIT 100
