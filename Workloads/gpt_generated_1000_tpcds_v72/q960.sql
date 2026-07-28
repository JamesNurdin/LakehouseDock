WITH store_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY cd.cd_gender
),
web_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY cd.cd_gender
)
SELECT gender,
       total_net_profit,
       channel
FROM store_sales_agg
UNION ALL
SELECT gender,
       total_net_profit,
       channel
FROM web_sales_agg
ORDER BY gender, channel
LIMIT 100
