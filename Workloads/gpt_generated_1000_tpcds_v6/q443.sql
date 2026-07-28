WITH cat_agg AS (
    SELECT DISTINCT
        p.p_promo_name AS promotion_name,
        td.t_hour AS hour_of_day,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_promo_sk = p.p_promo_sk) AS avg_profit_per_promo,
        (SELECT COUNT(DISTINCT hd3.hd_demo_sk)
         FROM household_demographics hd3
         WHERE hd3.hd_vehicle_count > 2) AS distinct_households_cnt
    FROM catalog_sales cs
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'N'
      AND td.t_hour BETWEEN 8 AND 20
      AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = cs.cs_ship_hdemo_sk
              AND hd2.hd_vehicle_count > 2
        )
    GROUP BY p.p_promo_name, td.t_hour, p.p_promo_sk
),
web_agg AS (
    SELECT DISTINCT
        p.p_promo_name AS promotion_name,
        td.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        (SELECT AVG(ws2.ws_net_profit)
         FROM web_sales ws2
         WHERE ws2.ws_promo_sk = p.p_promo_sk) AS avg_profit_per_promo,
        (SELECT COUNT(DISTINCT hd3.hd_demo_sk)
         FROM household_demographics hd3
         WHERE hd3.hd_vehicle_count > 2) AS distinct_households_cnt
    FROM web_sales ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'N'
      AND td.t_hour BETWEEN 8 AND 20
      AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = ws.ws_ship_hdemo_sk
              AND hd2.hd_vehicle_count > 2
        )
    GROUP BY p.p_promo_name, td.t_hour, p.p_promo_sk
)
SELECT promotion_name,
       hour_of_day,
       total_net_profit,
       total_quantity,
       avg_profit_per_promo,
       distinct_households_cnt
FROM (
    SELECT promotion_name, hour_of_day, total_net_profit, total_quantity, avg_profit_per_promo, distinct_households_cnt
    FROM cat_agg
    UNION ALL
    SELECT promotion_name, hour_of_day, total_net_profit, total_quantity, avg_profit_per_promo, distinct_households_cnt
    FROM web_agg
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
