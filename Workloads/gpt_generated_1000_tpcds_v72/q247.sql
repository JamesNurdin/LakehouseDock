WITH ss_agg AS (
    SELECT
        td.t_hour AS hour,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Clearance%'
      AND td.t_am_pm = 'AM'
    GROUP BY td.t_hour, p.p_promo_name
    HAVING SUM(ss.ss_net_profit) > 1000
),
ws_agg AS (
    SELECT
        td.t_hour AS hour,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
      AND td.t_am_pm = 'PM'
    GROUP BY td.t_hour, p.p_promo_name
    HAVING SUM(ws.ws_net_profit) > 500
)
SELECT DISTINCT
    hour,
    promo_name,
    total_profit
FROM (
    SELECT hour, promo_name, total_profit FROM ss_agg
    UNION ALL
    SELECT hour, promo_name, total_profit FROM ws_agg
) combined
ORDER BY total_profit DESC
LIMIT 100
