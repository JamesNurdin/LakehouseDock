WITH base_sales AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS product_name,
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS profit,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND s.s_state = 'CA'
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
    UNION ALL
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS profit,
        ws.ws_bill_customer_sk AS customer_sk,
        NULL AS store_sk,
        ws.ws_order_number AS ticket_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_ticket_number = ws.ws_order_number
      )
)
SELECT
    bs.item_sk,
    bs.product_name,
    bs.channel,
    bs.date_sk,
    bs.net_paid,
    bs.profit,
    COUNT(DISTINCT bs.customer_sk) OVER (PARTITION BY bs.item_sk) AS distinct_customer_count,
    SUM(DISTINCT bs.net_paid) OVER (PARTITION BY bs.item_sk) AS distinct_net_paid_sum,
    LAG(bs.profit) OVER (PARTITION BY bs.channel ORDER BY bs.date_sk) AS prev_profit,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = bs.item_sk) AS avg_item_price
FROM base_sales bs
ORDER BY bs.channel, bs.date_sk DESC
LIMIT 100
