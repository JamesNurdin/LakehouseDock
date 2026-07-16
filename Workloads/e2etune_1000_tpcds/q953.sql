WITH ws_agg AS (
    SELECT
        ws_promo_sk,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451185
    GROUP BY ws_promo_sk
    HAVING SUM(ws_net_profit) > 1000
)
SELECT
    p.p_promo_name,
    p.p_channel_tv,
    p.p_start_date_sk,
    p.p_end_date_sk,
    a.num_orders,
    a.total_net_profit,
    a.total_sales,
    a.avg_discount,
    a.total_quantity,
    ROW_NUMBER() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM ws_agg a
JOIN promotion p
    ON a.ws_promo_sk = p.p_promo_sk
WHERE p.p_channel_tv = 'TV'
  AND p.p_discount_active = 'Y'
ORDER BY a.total_net_profit DESC
LIMIT 100
