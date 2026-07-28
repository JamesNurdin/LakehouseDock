WITH store_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ss.ss_ext_sales_price AS sales_amount,
        p.p_promo_name AS promo_name,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_radio = 'Y'
      )
),
web_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ws.ws_ext_sales_price AS sales_amount,
        p.p_promo_name AS promo_name,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND p.p_channel_radio = 'Y'
)
SELECT
    customer_id,
    sales_amount,
    promo_name,
    sales_channel
FROM store_part
UNION ALL
SELECT
    customer_id,
    sales_amount,
    promo_name,
    sales_channel
FROM web_part
ORDER BY sales_amount DESC
LIMIT 100
