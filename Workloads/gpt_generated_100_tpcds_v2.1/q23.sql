WITH high_price_sales AS (
    SELECT
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_current_price >= 100.00
      AND cd.cd_marital_status = 'M'
      AND cd.cd_education_status = 'College'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 120000
      AND p.p_cost > 0
    GROUP BY i.i_category, cd.cd_gender
),
low_price_sales AS (
    SELECT
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_current_price < 100.00
      AND cd.cd_marital_status = 'W'
      AND cd.cd_education_status = 'Secondary'
      AND hd.hd_vehicle_count = 0
      AND ib.ib_upper_bound > 120000
      AND p.p_cost > 0
    GROUP BY i.i_category, cd.cd_gender
)
SELECT category, gender, total_sales, avg_profit, order_count
FROM high_price_sales
UNION ALL
SELECT category, gender, total_sales, avg_profit, order_count
FROM low_price_sales
ORDER BY total_sales DESC
LIMIT 100
