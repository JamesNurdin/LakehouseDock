WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        i.i_product_name,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        web.web_site_id,
        web.web_name,
        web.web_city,
        web.web_county,
        d.d_year
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2}')
      AND web.web_county LIKE '%County%'
      AND d.d_year = 2000
)
SELECT
    fs.web_site_id,
    fs.web_name,
    CONCAT(substr(fs.web_name, 1, 5), '_', fs.web_city) AS site_desc,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    SUM(fs.ws_quantity) AS total_quantity,
    SUM(fs.ws_net_paid) AS total_net_paid,
    SUM(fs.ws_net_profit) AS total_net_profit,
    REGEXP_EXTRACT(MIN(fs.i_product_name), '(\\d+)') AS example_product_number
FROM filtered_sales fs
GROUP BY fs.web_site_id, fs.web_name, fs.web_city
ORDER BY total_net_profit DESC
LIMIT 100
