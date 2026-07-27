WITH cs_data AS (
    SELECT c.c_customer_id AS customer_id,
           cs.cs_order_number AS order_number,
           cs.cs_net_profit AS net_profit,
           p.p_promo_name AS promo_name,
           sm.sm_type AS ship_type,
           w.w_city AS city,
           (
               SELECT max(cs2.cs_ext_sales_price)
               FROM catalog_sales cs2
               WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
           ) AS max_customer_sales
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_tv = 'N'
      AND w.w_city = 'Shiloh'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
),
ws_data AS (
    SELECT c2.c_customer_id AS customer_id,
           ws.ws_order_number AS order_number,
           ws.ws_net_profit AS net_profit,
           p2.p_promo_name AS promo_name,
           sm2.sm_type AS ship_type,
           w2.w_city AS city,
           CAST(NULL AS decimal(7,2)) AS max_customer_sales
    FROM web_sales ws
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    WHERE p2.p_channel_tv = 'N'
      AND w2.w_city = 'Shiloh'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = ws.ws_order_number
            AND cr.cr_return_quantity > 0
      )
)
SELECT customer_id,
       order_number,
       net_profit,
       promo_name,
       ship_type,
       city,
       max_customer_sales
FROM cs_data
UNION ALL
SELECT customer_id,
       order_number,
       net_profit,
       promo_name,
       ship_type,
       city,
       max_customer_sales
FROM ws_data
LIMIT 100
