SELECT
    c.c_customer_id AS customer_id,
    SUM(ss.ss_net_profit) AS net_profit,
    'store' AS sales_channel,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_quantity) AS total_quantity,
    p.p_promo_name AS promo_name
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
GROUP BY c.c_customer_id, p.p_promo_name

UNION ALL

SELECT
    c.c_customer_id AS customer_id,
    SUM(ws.ws_net_profit) AS net_profit,
    'web' AS sales_channel,
    COUNT(DISTINCT ws.ws_order_number) AS num_transactions,
    SUM(ws.ws_quantity) AS total_quantity,
    p.p_promo_name AS promo_name
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
GROUP BY c.c_customer_id, p.p_promo_name
