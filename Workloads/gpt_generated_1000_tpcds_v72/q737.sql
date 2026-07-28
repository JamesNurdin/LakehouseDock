WITH store_hourly AS (
    SELECT
        td.t_hour AS hour,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_brand = 'Brand#23'
      AND td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
),
web_hourly AS (
    SELECT
        td.t_hour AS hour,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_brand = 'Brand#23'
      AND td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
)
SELECT
    hour,
    channel,
    total_profit,
    total_discount,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT hour, channel, total_profit, total_discount FROM store_hourly
    UNION ALL
    SELECT hour, channel, total_profit, total_discount FROM web_hourly
) AS combined
ORDER BY channel, profit_rank
LIMIT 100
