WITH high_income_demo AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
)
SELECT *
FROM (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           'catalog' AS channel,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN high_income_demo hid ON cs.cs_bill_hdemo_sk = hid.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_start_date_sk <= 2450350
      AND p.p_end_date_sk >= 2450350
    GROUP BY cs.cs_sold_date_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk AS sold_date_sk,
           'web' AS channel,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(*) AS order_count
    FROM web_sales ws
    JOIN high_income_demo hid ON ws.ws_bill_hdemo_sk = hid.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_start_date_sk <= 2450350
      AND p.p_end_date_sk >= 2450350
    GROUP BY ws.ws_sold_date_sk
) AS combined
ORDER BY total_net_profit DESC, sold_date_sk DESC
LIMIT 100
