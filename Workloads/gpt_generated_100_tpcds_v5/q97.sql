WITH sales_with_details AS (
    SELECT
        ws.ws_order_number,
        i.i_brand,
        i.i_product_name,
        regexp_extract(i.i_product_name, '([0-9]{2})', 1) AS prod_code,
        ws.ws_net_paid_inc_ship_tax,
        wp.wp_url,
        wsite.web_city
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE regexp_like(i.i_product_name, '^[A-Z]{3}[0-9]{2}$')
      AND wp.wp_url LIKE '%foo.com%'
      AND substr(wsite.web_city, 1, 1) = 'S'
)
SELECT
    i_brand AS brand,
    prod_code,
    count(DISTINCT ws_order_number) AS order_cnt,
    sum(ws_net_paid_inc_ship_tax) AS total_net_paid,
    concat(i_brand, ' - ', substr(web_city, 1, 10)) AS brand_city_label
FROM sales_with_details
GROUP BY i_brand, prod_code, web_city
ORDER BY total_net_paid DESC
LIMIT 100
