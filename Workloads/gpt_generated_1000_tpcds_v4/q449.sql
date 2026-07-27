WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_brand,
        i.i_item_desc,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        web_site.web_county,
        web_site.web_name,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
        CONCAT(web_site.web_county, ' - ', web_site.web_name) AS location
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE REGEXP_LIKE(web_site.web_name, 'Online')
      AND i.i_item_desc LIKE '%steel%'
)
SELECT
    sd.web_county,
    sd.web_name,
    sd.location,
    sd.i_brand,
    sd.first_word_desc,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    SUM(sd.ws_net_profit) AS total_profit,
    COUNT(DISTINCT sd.ws_order_number) AS distinct_orders
FROM sales_data sd
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = sd.ws_item_sk
      AND cr.cr_return_amount > 1000
)
GROUP BY
    sd.web_county,
    sd.web_name,
    sd.location,
    sd.i_brand,
    sd.first_word_desc
ORDER BY total_sales DESC
LIMIT 100
