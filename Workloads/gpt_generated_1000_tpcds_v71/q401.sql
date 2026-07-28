WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_list_price,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number
    FROM tpcds.web_sales ws
    WHERE ws.ws_list_price BETWEEN 10 AND 150
      AND ws.ws_net_paid_inc_tax > 500
      AND ws.ws_quantity >= 1
      AND ws.ws_order_number <= 1000
), filtered_sites AS (
    SELECT
        site.web_site_sk,
        site.web_name,
        site.web_state,
        site.web_class,
        site.web_street_type
    FROM tpcds.web_site site
    WHERE site.web_state = 'CA'
      AND site.web_class = 'Unknown'
      AND site.web_street_type IN ('ST', 'Lane', 'Road')
)
SELECT
    fs.web_name,
    fs.web_state,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales_inc_tax,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_list_price) AS min_list_price,
    MAX(ws.ws_list_price) AS max_list_price
FROM filtered_sales ws
JOIN filtered_sites fs ON ws.ws_web_site_sk = fs.web_site_sk
GROUP BY fs.web_name, fs.web_state
ORDER BY total_sales_inc_tax DESC
LIMIT 100
