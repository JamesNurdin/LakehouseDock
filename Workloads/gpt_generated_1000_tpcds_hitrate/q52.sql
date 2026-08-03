/* goal: Compare top sales amounts of preferred versus non‑preferred customers across store and web channels, showing the number of promotions linked to each sold item. */
WITH store_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ss.ss_net_paid AS sales_amount,
        'store' AS channel,
        (
            SELECT COUNT(*)
            FROM promotion p
            WHERE p.p_item_sk = ss.ss_item_sk
        ) AS promo_count
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND s.s_market_id = 5
),
web_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ws.ws_net_paid AS sales_amount,
        'web' AS channel,
        (
            SELECT COUNT(*)
            FROM promotion p
            WHERE p.p_item_sk = ws.ws_item_sk
        ) AS promo_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND wp.wp_image_count > 3
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = ws.ws_item_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM web_part
ORDER BY sales_amount DESC, customer_id
LIMIT 100
