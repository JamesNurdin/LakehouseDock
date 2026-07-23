WITH base AS (
    SELECT
        t.t_hour,
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_current_price,
        cc.cc_state,
        sm.sm_code,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        r.r_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount
    FROM
        time_dim t
        JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE
        i.i_current_price > 100.00
        AND sm.sm_code = 'AIR'
        AND cc.cc_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        s_store_id,
        s_store_name,
        i_item_id,
        t_hour,
        r_reason_sk,
        SUM(cs_net_profit + ss_net_profit + ws_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY
        s_store_id,
        s_store_name,
        i_item_id,
        t_hour,
        r_reason_sk
)
SELECT
    s_store_id,
    s_store_name,
    i_item_id,
    t_hour,
    total_net_profit,
    CASE
        WHEN total_net_profit >= (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS store_profit_rank,
    DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_reason_sk = aggregated.r_reason_sk) AS total_returns_for_reason
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
