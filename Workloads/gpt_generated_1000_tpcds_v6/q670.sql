WITH base AS (
    SELECT
        d_ss.d_year                                    AS d_year,
        s.s_store_id                                    AS store_id,
        we.web_site_id                                 AS web_site_id,
        p.p_promo_id                                   AS promo_id,
        ss.ss_ext_sales_price                          AS store_sales,
        ws.ws_ext_sales_price                          AS web_sales,
        COALESCE(sr.sr_return_amt, 0)                  AS store_return_amt,
        COALESCE(wr.wr_return_amt, 0)                  AS web_return_amt,
        ss.ss_net_profit                               AS store_profit,
        ws.ws_net_profit                               AS web_profit,
        COALESCE(sr.sr_net_loss, 0)                    AS store_net_loss,
        COALESCE(wr.wr_net_loss, 0)                    AS web_net_loss,
        hd.hd_vehicle_count                            AS vehicle_count,
        ib.ib_upper_bound                              AS income_upper,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper,
        -- additional columns used only for filtering
        s.s_state,
        p.p_channel_event,
        ws.ws_ext_sales_price AS ws_price,
        we.web_country
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    -- Web‑sales and its dimensions
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_ss.d_date_sk
                     AND ws.ws_sold_time_sk = t_ss.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    -- Catalog page (joined via the same date dimension used for store sales)
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ss.d_date_sk
    -- Additional filters applied later in the outer query
    WHERE d_ss.d_year = 2001                           -- filter 1
      AND s.s_state = 'CA'                             -- filter 2
      AND p.p_channel_event = 'N'                      -- filter 3
      AND hd.hd_vehicle_count > 0                     -- filter 4
      AND ws.ws_ext_sales_price > 1000                -- filter 5
      AND we.web_country = 'United States'            -- filter 6
),
agg AS (
    SELECT
        d_year,
        store_id,
        web_site_id,
        promo_id,
        SUM(store_sales)            AS sum_store_sales,
        SUM(web_sales)              AS sum_web_sales,
        SUM(store_return_amt)       AS sum_store_returns,
        SUM(web_return_amt)         AS sum_web_returns,
        (SUM(store_profit) + SUM(web_profit) - SUM(store_net_loss) - SUM(web_net_loss)) AS total_profit,
        SUM(vehicle_count)          AS total_vehicle_count,
        MAX(max_income_upper)       AS max_income_upper
    FROM base
    GROUP BY ROLLUP (d_year, store_id, web_site_id, promo_id)
)
SELECT
    d_year,
    store_id,
    web_site_id,
    promo_id,
    sum_store_sales,
    sum_web_sales,
    sum_store_returns,
    sum_web_returns,
    total_profit,
    total_vehicle_count,
    max_income_upper,
    AVG(total_profit) OVER (PARTITION BY d_year)            AS avg_profit_by_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, store_id, web_site_id, promo_id
