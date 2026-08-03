WITH diff_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    EXCEPT
    SELECT cs.cs_order_number
    FROM catalog_sales cs
),
main AS (
    SELECT
        d_ss.d_year,
        st.s_store_name,
        i_ss.i_category,
        ss.ss_quantity,
        ss.ss_net_profit,
        SUM(ss.ss_net_profit) OVER (
            PARTITION BY d_ss.d_year
            ORDER BY ss.ss_sold_date_sk
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
        cr.cr_return_amount,
        r.r_reason_desc,
        ws.ws_net_profit AS web_net_profit,
        wr.wr_net_loss,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        diff.ws_order_number IS NOT NULL AS is_web_only_order,
        unnested_item_sk
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_ss.d_date_sk
        AND cs.cs_item_sk = i_ss.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_addr_sk = ca_ss.ca_address_sk
    ) lr ON true
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_ss.d_date_sk
        AND ws.ws_item_sk = i_ss.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN diff_orders diff ON ws.ws_order_number = diff.ws_order_number
    CROSS JOIN UNNEST(ARRAY[ss.ss_item_sk, ws.ws_item_sk]) AS t(unnested_item_sk)
)
SELECT
    d_year,
    s_store_name,
    i_category,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_profit) AS total_store_profit,
    MAX(cumulative_profit) AS cumulative_profit_year,
    profit_flag,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
    SUM(web_net_profit) AS total_web_profit,
    SUM(wr_net_loss) AS total_web_return_loss,
    MIN(ib_lower_bound) AS income_lower,
    MAX(ib_upper_bound) AS income_upper,
    COUNT_IF(is_web_only_order) AS web_only_orders,
    COUNT(DISTINCT unnested_item_sk) AS distinct_items_unnested
FROM main
GROUP BY
    d_year,
    s_store_name,
    i_category,
    profit_flag
ORDER BY d_year DESC, total_store_profit DESC
LIMIT 100
