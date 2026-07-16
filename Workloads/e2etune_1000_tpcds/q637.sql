SELECT
    category,
    ship_mode_type,
    income_band_lower,
    total_net_profit,
    total_quantity,
    avg_discount_amount,
    distinct_items_sold,
    distinct_pages,
    profit_rank
FROM (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_mode_type,
        ib.ib_lower_bound AS income_band_lower,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
        COUNT(DISTINCT wp.wp_url) AS distinct_pages,
        RANK() OVER (PARTITION BY ib.ib_lower_bound ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_buy_potential IN ('1001-5000', '>10000')
      AND ib.ib_lower_bound >= 20001
    GROUP BY i.i_category, sm.sm_type, ib.ib_lower_bound
    HAVING SUM(ws.ws_quantity) > 100
) sub
WHERE profit_rank <= 3
ORDER BY income_band_lower, profit_rank
