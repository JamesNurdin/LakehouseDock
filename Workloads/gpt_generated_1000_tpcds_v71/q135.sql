/* goal: Analyze store profit, return activity and inventory across stores, brands and time, applying multiple realistic filters and a semi‑join to web sales */
WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        i.i_brand,
        i.i_current_price,
        s.s_store_name,
        s.s_state,
        td.t_hour,
        td.t_am_pm,
        cr.cr_order_number,
        inv.inv_quantity_on_hand,
        cc.cc_gmt_offset,
        sm.sm_contract,
        w.w_state,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        ca.ca_state,
        hd.hd_buy_potential,
        c.c_customer_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE td.t_am_pm = 'PM'
      AND sm.sm_contract = 'fop0bcSd91J26IVpR'
      AND i.i_current_price BETWEEN 50 AND 200
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
            AND ws.ws_quantity > 10
            AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
      )
)
SELECT
    s_store_name,
    s_state,
    i_brand,
    i_current_price,
    t_hour,
    t_am_pm,
    SUM(ss_net_profit) AS total_store_profit,
    COUNT(DISTINCT cr_order_number) AS returns_count,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(cc_gmt_offset) AS min_call_center_gmt_offset,
    MAX(ib_upper_bound) AS max_income_upper_bound
FROM filtered_sales
GROUP BY
    s_store_name,
    s_state,
    i_brand,
    i_current_price,
    t_hour,
    t_am_pm
ORDER BY total_store_profit DESC
LIMIT 100
