WITH
  store_agg AS (
    SELECT
      i.i_brand,
      i.i_product_name,
      concat(i.i_brand, ' ', i.i_product_name) AS brand_product,
      ca.ca_city,
      sum(ss.ss_net_profit) AS store_profit,
      sum(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)brush')
      AND ca.ca_city LIKE 'San%'
    GROUP BY
      i.i_brand,
      i.i_product_name,
      ca.ca_city,
      concat(i.i_brand, ' ', i.i_product_name)
  ),
  web_agg AS (
    SELECT
      i.i_brand,
      i.i_product_name,
      concat(i.i_brand, ' ', i.i_product_name) AS brand_product,
      ca.ca_city,
      sum(ws.ws_net_profit) AS web_profit,
      sum(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)brush')
      AND ca.ca_city LIKE 'San%'
    GROUP BY
      i.i_brand,
      i.i_product_name,
      ca.ca_city,
      concat(i.i_brand, ' ', i.i_product_name)
  )
SELECT
  brand_product,
  ca_city,
  sum(store_profit) AS total_store_profit,
  sum(web_profit) AS total_web_profit,
  sum(store_qty) AS total_store_qty,
  sum(web_qty) AS total_web_qty,
  (sum(store_profit) + sum(web_profit)) AS total_profit
FROM (
  SELECT brand_product, ca_city, store_profit, NULL AS web_profit, store_qty, NULL AS web_qty
  FROM store_agg
  UNION ALL
  SELECT brand_product, ca_city, NULL, web_profit, NULL, web_qty
  FROM web_agg
) combined
GROUP BY brand_product, ca_city
ORDER BY total_profit DESC
LIMIT 100
