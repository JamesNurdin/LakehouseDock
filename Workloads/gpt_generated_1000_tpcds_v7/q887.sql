WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        ib.ib_lower_bound,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        sr.sr_net_loss AS return_loss,
        inv.inv_quantity_on_hand AS qty_on_hand
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_shift = 'first'
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
),
store_metrics AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        SUM(store_profit) AS total_store_profit,
        SUM(web_profit) AS total_web_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(qty_on_hand) AS total_qty_on_hand,
        AVG(ib_lower_bound) AS avg_income_lower_bound
    FROM base
    GROUP BY s_store_sk, s_store_name, s_state
)
SELECT
    s_state,
    AVG(total_store_profit + total_web_profit - total_return_loss) AS avg_combined_profit
FROM store_metrics
WHERE total_qty_on_hand > 1000
GROUP BY s_state
HAVING AVG(total_store_profit + total_web_profit - total_return_loss) > 10000
ORDER BY avg_combined_profit DESC
LIMIT 10
