WITH
    ss_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            d_ss.d_year,
            d_ss.d_quarter_name,
            ib_ss.ib_income_band_sk AS income_band_sk,
            SUM(ss.ss_net_profit) AS ss_net_profit,
            SUM(ss.ss_quantity) AS ss_quantity
        FROM store_sales ss
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN income_band ib_ss ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
        WHERE d_ss.d_year = 1907
          AND t_ss.t_am_pm = 'PM'
          AND s.s_state = 'CA'
          AND ib_ss.ib_upper_bound <= 50000
        GROUP BY s.s_store_sk, s.s_store_name, d_ss.d_year, d_ss.d_quarter_name, ib_ss.ib_income_band_sk
    ),
    sr_agg AS (
        SELECT
            s.s_store_sk,
            d_sr.d_year,
            ib_sr.ib_income_band_sk AS income_band_sk,
            SUM(sr.sr_net_loss) AS sr_net_loss
        FROM store_returns sr
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE d_sr.d_year = 1907
          AND t_sr.t_am_pm = 'PM'
          AND s.s_state = 'CA'
          AND ib_sr.ib_upper_bound <= 50000
        GROUP BY s.s_store_sk, d_sr.d_year, ib_sr.ib_income_band_sk
    ),
    cs_agg AS (
        SELECT
            d_cs.d_year,
            ib_cs_bill.ib_income_band_sk AS income_band_sk,
            SUM(cs.cs_net_profit) AS cs_net_profit
        FROM catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
        JOIN income_band ib_cs_bill ON hd_cs_bill.hd_income_band_sk = ib_cs_bill.ib_income_band_sk
        JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
        JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        WHERE d_cs.d_year = 1907
          AND t_cs.t_am_pm = 'PM'
          AND ib_cs_bill.ib_upper_bound <= 50000
        GROUP BY d_cs.d_year, ib_cs_bill.ib_income_band_sk
    ),
    ws_agg AS (
        SELECT
            we.web_site_sk,
            we.web_name,
            d_ws.d_year,
            ib_ws_bill.ib_income_band_sk AS income_band_sk,
            SUM(ws.ws_net_profit) AS ws_net_profit
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        JOIN income_band ib_ws_bill ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
        JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        WHERE d_ws.d_year = 1907
          AND t_ws.t_am_pm = 'PM'
          AND we.web_name = 'WebSiteA'
          AND ib_ws_bill.ib_upper_bound <= 50000
        GROUP BY we.web_site_sk, we.web_name, d_ws.d_year, ib_ws_bill.ib_income_band_sk
    ),
    wr_agg AS (
        SELECT
            we.web_site_sk,
            we.web_name,
            d_wr.d_year,
            ib_wr_refund.ib_income_band_sk AS income_band_sk,
            SUM(wr.wr_net_loss) AS wr_net_loss
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
        JOIN income_band ib_wr_refund ON hd_wr_refund.hd_income_band_sk = ib_wr_refund.ib_income_band_sk
        JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        WHERE d_wr.d_year = 1907
          AND t_wr.t_am_pm = 'PM'
          AND we.web_name = 'WebSiteA'
          AND ib_wr_refund.ib_upper_bound <= 50000
        GROUP BY we.web_site_sk, we.web_name, d_wr.d_year, ib_wr_refund.ib_income_band_sk
    ),
    combined AS (
        SELECT
            ss.s_store_name AS store_name,
            CAST(NULL AS varchar) AS web_site_name,
            ss.d_year AS year,
            ss.d_quarter_name AS quarter_name,
            ss.income_band_sk AS income_band,
            (ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit
        FROM ss_agg ss
        LEFT JOIN sr_agg sr
            ON ss.s_store_sk = sr.s_store_sk
           AND ss.d_year = sr.d_year
           AND ss.income_band_sk = sr.income_band_sk
        LEFT JOIN cs_agg cs
            ON ss.d_year = cs.d_year
           AND ss.income_band_sk = cs.income_band_sk
        UNION ALL
        SELECT
            CAST(NULL AS varchar) AS store_name,
            ws.web_name AS web_site_name,
            ws.d_year AS year,
            CAST(NULL AS varchar) AS quarter_name,
            ws.income_band_sk AS income_band,
            (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS total_net_profit
        FROM ws_agg ws
        LEFT JOIN wr_agg wr
            ON ws.web_site_sk = wr.web_site_sk
           AND ws.d_year = wr.d_year
           AND ws.income_band_sk = wr.income_band_sk
    )
SELECT
    store_name,
    web_site_name,
    year,
    quarter_name,
    income_band,
    sum_total_net_profit,
    CASE
        WHEN sum_total_net_profit > 20000 THEN 'High'
        WHEN sum_total_net_profit BETWEEN 5000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY year ORDER BY sum_total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        store_name,
        web_site_name,
        year,
        quarter_name,
        income_band,
        SUM(total_net_profit) AS sum_total_net_profit
    FROM combined
    GROUP BY store_name, web_site_name, year, quarter_name, income_band
    HAVING SUM(total_net_profit) > 0
) agg
ORDER BY sum_total_net_profit DESC
LIMIT 100
