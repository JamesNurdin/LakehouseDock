WITH item_sales AS (
    SELECT
        ws.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450120
)
SELECT
    isales.i_item_id,
    isales.i_product_name,
    wsit.web_name,
    isales.ws_quantity,
    isales.ws_ext_sales_price,
    (SELECT SUM(ws2.ws_ext_sales_price)
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = isales.ws_item_sk) AS total_sales_all_sites
FROM item_sales isales
JOIN web_site wsit ON isales.ws_web_site_sk = wsit.web_site_sk
WHERE wsit.web_name = 'SiteA'
  AND isales.i_item_id IN (
        SELECT i2.i_item_id
        FROM item i2
        WHERE i2.i_brand = 'BrandX'
      )
UNION ALL
SELECT
    isales2.i_item_id,
    isales2.i_product_name,
    wsit2.web_name,
    isales2.ws_quantity,
    isales2.ws_ext_sales_price,
    (SELECT SUM(ws2.ws_ext_sales_price)
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = isales2.ws_item_sk) AS total_sales_all_sites
FROM item_sales isales2
JOIN web_site wsit2 ON isales2.ws_web_site_sk = wsit2.web_site_sk
WHERE wsit2.web_name = 'SiteB'
  AND EXISTS (
        SELECT 1
        FROM customer c
        JOIN web_sales ws3 ON ws3.ws_bill_customer_sk = c.c_customer_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND ws3.ws_item_sk = isales2.ws_item_sk
      )
LIMIT 100
