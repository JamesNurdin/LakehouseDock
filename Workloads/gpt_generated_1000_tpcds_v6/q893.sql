WITH sales_enriched AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        t.t_hour,
        t.t_meal_time,
        p.p_promo_name,
        p.p_channel_event,
        p.p_channel_demo
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'N'
      AND p.p_channel_demo = 'N'
      AND t.t_hour BETWEEN 8 AND 20
      AND t.t_meal_time = 'Lunch'
      AND ws.ws_sales_price > 20
      AND ws.ws_quantity >= 2
)
SELECT
    p_promo_name,
    t_hour,
    t_meal_time,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_sales_price) AS avg_sales_price,
    CASE
        WHEN SUM(ws_net_profit) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_status
FROM sales_enriched
GROUP BY p_promo_name, t_hour, t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
