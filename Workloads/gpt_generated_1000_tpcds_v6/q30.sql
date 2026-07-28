WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_web_page_sk,
        wp.wp_url
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_gender = 'M'
      AND regexp_like(wp.wp_url, '^https?://.*\\.html$')
      AND wp.wp_type LIKE 'C%'
      AND EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
      )
),
avg_profit AS (
    SELECT AVG(ws_net_profit) AS overall_avg_net_profit
    FROM web_sales
)
SELECT
    d.d_year,
    d.d_quarter_name,
    CONCAT(CAST(d.d_year AS varchar), '-', d.d_quarter_name) AS year_quarter,
    COUNT(DISTINCT sa.ws_order_number) AS orders,
    SUM(sa.ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN wr.wr_order_number IS NOT NULL THEN 1 ELSE 0 END) AS returned_orders,
    MAX(sa.wp_url) AS sample_url,
    regexp_extract(MAX(sa.wp_url), 'https?://([^/]+)/', 1) AS domain,
    ap.overall_avg_net_profit
FROM sales_agg sa
JOIN date_dim d ON sa.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = sa.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
CROSS JOIN avg_profit ap
GROUP BY d.d_year, d.d_quarter_name, CONCAT(CAST(d.d_year AS varchar), '-', d.d_quarter_name), ap.overall_avg_net_profit
ORDER BY total_net_profit DESC
LIMIT 100
