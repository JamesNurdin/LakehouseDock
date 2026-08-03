WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*sports')
      AND wp.wp_url LIKE '%example.com%'
),
agg_sales AS (
    SELECT
        wsit.web_name,
        d.d_year,
        i.i_brand,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_brand = i.i_brand
        ) AS avg_brand_profit
    FROM filtered_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    GROUP BY CUBE (wsit.web_name, d.d_year, i.i_brand)
)
SELECT
    web_name,
    d_year,
    i_brand,
    CONCAT('Brand-', i_brand) AS brand_label,
    total_profit,
    sales_cnt,
    profit_category,
    avg_brand_profit,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
FROM agg_sales
ORDER BY rn
LIMIT 100
