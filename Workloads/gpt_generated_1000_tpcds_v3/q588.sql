WITH cs_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        cc.cc_name,
        sm.sm_type AS cs_ship_mode_type,
        promo.p_promo_name AS cs_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales,
        SUM(cs.cs_ext_discount_amt) AS total_cs_discount,
        COUNT(DISTINCT cs.cs_order_number) AS cs_order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion promo ON cs.cs_promo_sk = promo.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND promo.p_response_target = 1
      AND cc.cc_state = 'CA'
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, cc.cc_name, sm.sm_type, promo.p_promo_name
),
ws_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        sm.sm_type AS ws_ship_mode_type,
        promo.p_promo_name AS ws_promo_name,
        wp.wp_type AS web_page_type,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        AVG(ws.ws_net_profit) AS avg_ws_profit,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion promo ON ws.ws_promo_sk = promo.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND wp.wp_type = 'Content'
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, sm.sm_type, promo.p_promo_name, wp.wp_type
),
sr_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt_inc_tax) AS total_sr_returns,
        COUNT(*) AS sr_return_cnt
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt_inc_tax > 1000
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential
)
SELECT
    cs.hd_buy_potential,
    cs.cc_name,
    cs.cs_ship_mode_type,
    cs.cs_promo_name,
    ws.web_page_type,
    ws.ws_ship_mode_type,
    SUM(cs.total_cs_sales) AS total_catalog_sales,
    SUM(ws.total_ws_sales) AS total_web_sales,
    SUM(sr.total_sr_returns) AS total_returns,
    SUM(cs.total_cs_discount) AS total_catalog_discount,
    AVG(ws.avg_ws_profit) AS avg_web_profit,
    SUM(cs.cs_order_cnt) AS total_catalog_orders,
    SUM(ws.ws_order_cnt) AS total_web_orders,
    SUM(sr.sr_return_cnt) AS total_return_transactions
FROM cs_agg cs
LEFT JOIN ws_agg ws ON cs.hd_demo_sk = ws.hd_demo_sk
LEFT JOIN sr_agg sr ON cs.hd_demo_sk = sr.hd_demo_sk
GROUP BY
    cs.hd_buy_potential,
    cs.cc_name,
    cs.cs_ship_mode_type,
    cs.cs_promo_name,
    ws.web_page_type,
    ws.ws_ship_mode_type
ORDER BY total_catalog_sales DESC
LIMIT 100
