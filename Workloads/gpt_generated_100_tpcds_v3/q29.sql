WITH store_items AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        (SELECT MIN(p2.p_start_date_sk)
         FROM promotion p2
         WHERE p2.p_item_sk = i.i_item_sk) AS first_promo_start_date_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p3
          WHERE p3.p_item_sk = i.i_item_sk
            AND p3.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    HAVING SUM(ss.ss_net_profit) > 1000
),
web_items AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        (SELECT MIN(p2.p_start_date_sk)
         FROM promotion p2
         WHERE p2.p_item_sk = i.i_item_sk) AS first_promo_start_date_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id IN (
          SELECT DISTINCT i2.i_brand_id
          FROM item i2
          WHERE i2.i_category = 'Electronics'
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    item_id,
    product_name,
    total_quantity,
    total_net_profit,
    avg_sales_price,
    first_promo_start_date_sk
FROM store_items
UNION ALL
SELECT
    item_id,
    product_name,
    total_quantity,
    total_net_profit,
    avg_sales_price,
    first_promo_start_date_sk
FROM web_items
ORDER BY total_net_profit DESC
LIMIT 100
