WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
)
SELECT
    i.i_category,
    i.i_product_name,
    i.i_brand,
    regexp_extract(i.i_product_name, '([0-9]{2,4})') AS product_code,
    concat(i.i_brand, ':', i.i_product_name) AS brand_product,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(fs.ws_quantity) AS total_quantity
FROM filtered_sales fs
JOIN item i ON fs.ws_item_sk = i.i_item_sk
JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE regexp_like(i.i_product_name, '[0-9]{2,4}')
  AND wp.wp_url LIKE '%promo%'
  AND ca.ca_gmt_offset > -6.00
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_net_loss > 0
      )
GROUP BY
    i.i_category,
    i.i_product_name,
    i.i_brand,
    regexp_extract(i.i_product_name, '([0-9]{2,4})'),
    concat(i.i_brand, ':', i.i_product_name)
HAVING AVG(fs.ws_net_profit) > (
        SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2
      )
ORDER BY total_net_profit DESC
LIMIT 100
