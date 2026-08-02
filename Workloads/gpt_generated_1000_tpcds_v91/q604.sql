WITH bill_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 500 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_promo_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
      AND p.p_channel_event = 'N'
),
ship_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 500 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_promo_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
      AND p.p_channel_event = 'N'
)
SELECT order_number, item_sk, promo_sk, promo_name, net_profit, profit_flag
FROM (
    SELECT order_number, item_sk, promo_sk, promo_name, net_profit, profit_flag
    FROM bill_sales
    WHERE rn = 1
) AS bill_top
INTERSECT
SELECT order_number, item_sk, promo_sk, promo_name, net_profit, profit_flag
FROM (
    SELECT order_number, item_sk, promo_sk, promo_name, net_profit, profit_flag
    FROM ship_sales
    WHERE rn = 1
) AS ship_top
ORDER BY net_profit DESC
LIMIT 100
