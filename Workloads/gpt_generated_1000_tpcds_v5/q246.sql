WITH combined_sales AS (
    SELECT
        s.s_store_id,
        s.s_state,
        sm.sm_code,
        hd.hd_buy_potential,
        p.p_promo_name,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        ss.ss_quantity AS store_quantity,
        ws.ws_quantity AS web_quantity
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        hd.hd_buy_potential = '5001-10000'
        AND hd.hd_income_band_sk = 19
        AND p.p_discount_active = 'Y'
        AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
        AND ss.ss_wholesale_cost > 50
        AND ws.ws_ext_discount_amt < 500
)
SELECT
    s_store_id,
    s_state,
    sm_code,
    hd_buy_potential,
    p_promo_name,
    SUM(store_net_profit + web_net_profit) AS total_net_profit,
    SUM(store_quantity) AS total_store_qty,
    SUM(web_quantity) AS total_web_qty,
    COUNT(*) AS transaction_count
FROM combined_sales
GROUP BY s_store_id, s_state, sm_code, hd_buy_potential, p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
