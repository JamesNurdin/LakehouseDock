WITH filtered_sales AS (
    SELECT *
    FROM tpcds.web_sales
    WHERE ws_ext_list_price > 5000
      AND ws_ext_ship_cost BETWEEN 100 AND 2000
      AND ws_ship_customer_sk IN (5109405, 8592247)
      AND ws_quantity >= 2
      AND ws_net_profit > 0
),
joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        hd.hd_buy_potential,
        sm.sm_type,
        ws_site.web_name,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk
    FROM filtered_sales ws
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE sm.sm_code = 'AIR'
      AND hd.hd_income_band_sk = 15
      AND EXISTS (
            SELECT 1
            FROM tpcds.ship_mode sm2
            WHERE sm2.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
              AND sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
          )
)
SELECT
    jd.web_name,
    jd.sm_type,
    jd.hd_buy_potential,
    SUM(jd.ws_net_paid) AS total_net_paid,
    AVG(jd.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(*) AS order_count,
    MIN(jd.ws_net_profit) AS min_profit,
    MAX(jd.ws_net_profit) AS max_profit,
    ROW_NUMBER() OVER (PARTITION BY jd.web_name ORDER BY SUM(jd.ws_net_paid) DESC) AS rn
FROM joined_data jd
GROUP BY jd.web_name, jd.sm_type, jd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
