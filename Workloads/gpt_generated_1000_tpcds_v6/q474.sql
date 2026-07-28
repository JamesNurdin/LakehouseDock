WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        SUM(ss.ss_net_profit)                         AS store_sales_profit,
        SUM(ws.ws_net_profit)                         AS web_sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0))              AS returns_loss
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_hour BETWEEN 9 AND 17
        AND c_ss.c_preferred_cust_flag = 'Y'
        AND p.p_channel_dmail = 'Y'
        AND ib.ib_lower_bound >= 30000
        AND sm.sm_type = 'AIR'
        AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_state,
        d.d_year
)
SELECT
    s_store_id,
    s_state,
    d_year,
    store_sales_profit,
    web_sales_profit,
    returns_loss,
    (store_sales_profit + web_sales_profit - returns_loss) AS total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_sales_profit + web_sales_profit - returns_loss) DESC) AS profit_rank
FROM
    sales_agg
ORDER BY
    profit_rank,
    s_store_id
LIMIT 100
