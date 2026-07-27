WITH distinct_sales AS (
    SELECT DISTINCT
        p.p_promo_id AS promo_id,
        p.p_channel_demo AS channel_demo,
        ws.ws_order_number AS order_number,
        ws.ws_net_paid_inc_ship AS net_paid,
        ws.ws_sold_date_sk AS sold_date_sk
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
)
SELECT
    promo_id,
    channel_demo,
    SUM(net_paid) AS total_sales,
    COUNT(DISTINCT order_number) AS unique_orders
FROM (
    SELECT promo_id, channel_demo, order_number, net_paid
    FROM distinct_sales
    WHERE channel_demo = 'N' AND net_paid > 500

    UNION ALL

    SELECT promo_id, channel_demo, order_number, net_paid
    FROM distinct_sales
    WHERE channel_demo <> 'N' AND net_paid > 200
) unified
GROUP BY promo_id, channel_demo
HAVING SUM(net_paid) > 1000
ORDER BY total_sales DESC
LIMIT 100
