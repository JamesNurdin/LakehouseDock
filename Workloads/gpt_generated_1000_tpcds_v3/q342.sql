WITH filtered_items AS (
    SELECT DISTINCT i.i_item_sk,
           i.i_category,
           i.i_product_name,
           regexp_extract(i.i_product_name, '\\d{3}', 0) AS product_code
    FROM item i
    WHERE regexp_like(i.i_product_name, '\\d{3}')
)
SELECT
    (web_site.web_name || ' - ' || ship_mode.sm_code) AS combined_label,
    filtered_items.i_category,
    filtered_items.product_code,
    SUM(web_sales.ws_net_profit) AS total_profit,
    COUNT(DISTINCT web_sales.ws_order_number) AS distinct_orders
FROM web_sales
INNER JOIN filtered_items
    ON web_sales.ws_item_sk = filtered_items.i_item_sk
INNER JOIN web_site
    ON web_sales.ws_web_site_sk = web_site.web_site_sk
INNER JOIN ship_mode
    ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
INNER JOIN date_dim
    ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
WHERE ship_mode.sm_code LIKE 'A%'
  AND date_dim.d_year = 2001
  AND substring(web_site.web_manager, 1, 5) = 'Tommy'
GROUP BY (web_site.web_name || ' - ' || ship_mode.sm_code),
         filtered_items.i_category,
         filtered_items.product_code
HAVING SUM(web_sales.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
