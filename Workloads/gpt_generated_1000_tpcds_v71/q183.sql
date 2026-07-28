WITH filtered_web_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        wp.wp_url,
        i.i_category,
        i.i_item_desc,
        d.d_year
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, 'promo')
      AND i.i_item_desc LIKE '%COFFEE%'
)
SELECT
    f.i_category,
    f.d_year,
    regexp_extract(f.wp_url, 'promo/([^/]+)', 1) AS promo_code,
    SUM(f.ws_net_profit) AS total_net_profit,
    SUM(f.ws_quantity) AS total_quantity,
    COUNT(DISTINCT f.ws_order_number) AS distinct_orders
FROM filtered_web_sales f
GROUP BY
    f.i_category,
    f.d_year,
    regexp_extract(f.wp_url, 'promo/([^/]+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
