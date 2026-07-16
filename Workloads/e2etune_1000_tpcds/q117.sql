WITH daily_sales AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS daily_quantity,
        SUM(ws.ws_net_profit) AS daily_net_profit,
        AVG(ws.ws_ext_discount_amt) AS daily_avg_discount
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk, ws.ws_sold_date_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(p.p_channel_tv, 'N/A') AS channel_tv,
    SUM(ds.daily_quantity) AS total_quantity,
    SUM(ds.daily_net_profit) AS total_net_profit,
    AVG(ds.daily_avg_discount) AS avg_discount,
    RANK() OVER (PARTITION BY p.p_channel_tv ORDER BY SUM(ds.daily_net_profit) DESC) AS channel_profit_rank,
    SUM(SUM(ds.daily_net_profit)) OVER (ORDER BY SUM(ds.daily_net_profit) DESC) AS cum_net_profit
FROM daily_sales ds
JOIN promotion p
    ON ds.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON ds.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
WHERE
    d_sold.d_holiday = 'Y'
    AND d_start.d_year = 2002
    AND p.p_discount_active = 'Y'
    AND ds.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_tv
HAVING
    SUM(ds.daily_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 10
