WITH filtered_orders AS (
   SELECT ws_order_number
   FROM web_sales ws
   WHERE ws.ws_quantity > 1
     AND ws.ws_sales_price > 10
     AND ws.ws_ship_mode_sk IN (1, 2, 3)
     AND ws.ws_promo_sk IS NOT NULL
     AND ws.ws_bill_addr_sk IS NOT NULL
),
filtered_orders2 AS (
   SELECT ws_order_number
   FROM web_sales ws
   WHERE ws.ws_ext_discount_amt < 5
     AND ws.ws_net_profit > 0
     AND ws.ws_ship_date_sk BETWEEN 2452400 AND 2452500
     AND ws.ws_web_page_sk IN (
         SELECT wp_web_page_sk
         FROM web_page
         WHERE wp_max_ad_count >= 2
     )
     AND ws.ws_bill_addr_sk IN (
         SELECT ca_address_sk
         FROM customer_address
         WHERE ca_state = 'CA'
     )
),
common_orders AS (
   SELECT ws_order_number
   FROM filtered_orders
   INTERSECT
   SELECT ws_order_number
   FROM filtered_orders2
),
base AS (
   SELECT
       ws.ws_order_number       AS order_number,
       ws.ws_ext_sales_price    AS ext_sales_price,
       ws.ws_net_profit         AS net_profit,
       ws.ws_quantity           AS quantity,
       p.p_promo_name           AS promo_name,
       ca.ca_city               AS city,
       wp.wp_url                AS url,
       ws.ws_bill_customer_sk   AS bill_customer_sk
   FROM web_sales ws
   JOIN common_orders co       ON ws.ws_order_number = co.ws_order_number
   JOIN promotion p            ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer_address ca    ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE p.p_channel_catalog = 'N'
     AND p.p_purpose <> 'Unknown'
     AND ca.ca_state = 'CA'
     AND wp.wp_max_ad_count >= 1
     AND ws.ws_sold_date_sk BETWEEN 2452400 AND 2452600
)
SELECT
    order_number,
    ext_sales_price,
    net_profit,
    promo_name,
    city,
    url,
    SUM(quantity)                               AS total_quantity,
    (SELECT SUM(ws2.ws_quantity)
       FROM web_sales ws2
       WHERE ws2.ws_bill_customer_sk = base.bill_customer_sk) AS qty_by_customer,
    ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY ext_sales_price DESC) AS rn_promo
FROM base
GROUP BY
    order_number,
    ext_sales_price,
    net_profit,
    promo_name,
    city,
    url,
    bill_customer_sk
HAVING SUM(quantity) > 3
ORDER BY rn_promo, net_profit DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
