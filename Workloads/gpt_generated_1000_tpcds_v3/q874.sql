WITH ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_promo_sk,
        ws_warehouse_sk,
        ws_web_page_sk,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(ws_ext_ship_cost) AS sum_ws_ext_ship_cost,
        COUNT(*) AS ws_order_cnt
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_promo_sk, ws_warehouse_sk, ws_web_page_sk
)

SELECT
    d_cs.d_year AS sales_year,
    p_cs.p_promo_name AS promo_name,
    cd_bill.cd_gender AS gender,
    hd_bill.hd_income_band_sk AS income_band,
    CASE WHEN d_cs.d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END AS holiday_flag,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws_agg.sum_ws_net_paid) AS total_web_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws_agg.sum_ws_net_paid) - SUM(ws_agg.sum_ws_ext_ship_cost) AS total_web_profit,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + (SUM(ws_agg.sum_ws_net_paid) - SUM(ws_agg.sum_ws_ext_ship_cost))) AS total_combined_profit
FROM catalog_sales cs
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN ws_agg
    ON ws_agg.ws_sold_date_sk = d_cs.d_date_sk
JOIN promotion p_ws
    ON ws_agg.ws_promo_sk = p_ws.p_promo_sk
JOIN warehouse w_ws
    ON ws_agg.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE d_cs.d_year = 2001
GROUP BY
    d_cs.d_year,
    p_cs.p_promo_name,
    cd_bill.cd_gender,
    hd_bill.hd_income_band_sk,
    d_cs.d_holiday
HAVING (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + (SUM(ws_agg.sum_ws_net_paid) - SUM(ws_agg.sum_ws_ext_ship_cost))) > 1000000
ORDER BY total_combined_profit DESC
LIMIT 100
