WITH joined AS (
    SELECT
        d_ss.d_year,
        s.s_state,
        cp.cp_type,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price            AS store_sales_price,
        ss.ss_net_profit                 AS store_net_profit,
        cs.cs_ext_sales_price            AS catalog_sales_price,
        cs.cs_net_profit                 AS catalog_net_profit,
        cr.cr_return_amount              AS catalog_return_amount,
        sr.sr_return_amt                 AS store_return_amount,
        wr.wr_return_amt                 AS web_return_amount,
        r.r_reason_desc                  AS store_return_reason,
        r2.r_reason_desc                 AS catalog_return_reason,
        r3.r_reason_desc                 AS web_return_reason,
        sm.sm_type,
        w.w_warehouse_name,
        cc.cc_name,
        ib.ib_upper_bound,
        -- join auxiliary date and time dims for web returns (used only for join validity)
        d_wr.d_date_sk,
        t_wr.t_time_sk
    FROM store_sales ss
    JOIN date_dim d_ss          ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss          ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s                ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs        ON cs.cs_sold_date_sk = d_ss.d_date_sk
    JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm           ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w            ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r2          ON cr.cr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_returns wr    ON wr.wr_order_number = cs.cs_order_number
    LEFT JOIN reason r3          ON wr.wr_reason_sk = r3.r_reason_sk
    LEFT JOIN web_page wp        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wr     ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr     ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE d_ss.d_year = 2001
      AND s.s_state = 'TX'
      AND cc.cc_market_manager LIKE '%Manager%'
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound >= 50000
)
SELECT
    d_year,
    s_state,
    cp_type,
    CASE
        WHEN total_sales > 1000000 THEN 'High'
        ELSE 'Medium'
    END AS sales_category,
    total_sales,
    total_profit,
    distinct_txns,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        d_year,
        s_state,
        cp_type,
        SUM(store_sales_price)   + SUM(catalog_sales_price)   AS total_sales,
        SUM(store_net_profit)    + SUM(catalog_net_profit)    AS total_profit,
        COUNT(DISTINCT ss_ticket_number)               AS distinct_txns
    FROM joined
    GROUP BY GROUPING SETS (
        (d_year, s_state, cp_type),
        (d_year, s_state),
        (d_year)
    )
) agg
ORDER BY d_year, s_state, total_sales DESC
LIMIT 100
