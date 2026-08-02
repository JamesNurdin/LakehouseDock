WITH target_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 1999
)
SELECT
    u.c_customer_id,
    u.c_first_name,
    u.c_last_name,
    u.total_net_profit,
    u.total_sales,
    u.orders,
    COALESCE((SELECT SUM(ss3.ss_ext_discount_amt)
              FROM store_sales ss3
              WHERE ss3.ss_customer_sk = u.c_customer_sk), 0) AS total_store_discount
FROM (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM store_sales ss
    JOIN target_dates td ON ss.ss_sold_date_sk = td.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS orders
    FROM web_sales ws
    JOIN target_dates td ON ws.ws_sold_date_sk = td.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
) u
ORDER BY u.total_net_profit DESC
LIMIT 100
