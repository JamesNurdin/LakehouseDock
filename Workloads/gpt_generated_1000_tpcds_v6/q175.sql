WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        i.i_manufact,
        i.i_current_price,
        i.i_item_sk,
        wp.wp_url,
        t.t_hour,
        CONCAT(i.i_manufact, '-', CAST(i.i_item_sk AS varchar)) AS manufact_item_key,
        SUBSTRING(wp.wp_url FROM 1 FOR 20) AS url_prefix,
        CASE WHEN i.i_current_price > 5 THEN 'expensive' ELSE 'cheap' END AS price_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_manufact, '^.*anti.*$')
      AND wp.wp_url LIKE 'http%://%store%'
)
SELECT
    manufact_item_key,
    i_manufact,
    t_hour,
    price_category,
    SUM(ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_quantity) AS total_quantity,
    url_prefix
FROM sales_data
GROUP BY
    manufact_item_key,
    i_manufact,
    t_hour,
    price_category,
    url_prefix
ORDER BY total_net_paid DESC
LIMIT 100
