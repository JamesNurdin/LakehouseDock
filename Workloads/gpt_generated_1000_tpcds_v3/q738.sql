WITH sales_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        td_ws.t_hour AS sale_hour,
        td_sr.t_hour AS return_hour,
        inv.inv_quantity_on_hand,
        r.r_reason_desc AS return_reason,
        sm.sm_ship_mode_id,
        (ws.ws_net_profit - sr.sr_net_loss) AS net_contribution
    FROM
        store_returns sr
        JOIN time_dim td_sr
            ON sr.sr_return_time_sk = td_sr.t_time_sk
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
        LEFT JOIN time_dim td_wr
            ON wr.wr_returned_time_sk = td_wr.t_time_sk
        LEFT JOIN reason r_wr
            ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        i.i_current_price BETWEEN 20 AND 200
        AND ib.ib_upper_bound >= 50000
        AND inv.inv_quantity_on_hand > 0
        AND td_ws.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND r.r_reason_desc LIKE '%size%'
        AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
              AND p.p_channel_demo = 'N'
        )
)
SELECT
    t.s_store_id,
    t.s_state,
    t.total_ws_net_profit,
    t.total_sr_net_loss,
    t.net_contribution,
    DENSE_RANK() OVER (ORDER BY t.net_contribution DESC) AS net_rank
FROM (
    SELECT
        s_store_id,
        s_state,
        SUM(ws_net_profit) AS total_ws_net_profit,
        SUM(sr_net_loss) AS total_sr_net_loss,
        SUM(net_contribution) AS net_contribution
    FROM sales_data
    GROUP BY s_store_id, s_state
) t
ORDER BY net_rank
LIMIT 100
