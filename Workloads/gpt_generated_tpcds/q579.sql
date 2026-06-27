WITH
    /* Store channel sales */
    store_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            SUM(ss.ss_net_profit) AS total_profit,
            0.0 AS total_loss
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Store channel returns */
    store_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            0.0 AS total_profit,
            SUM(sr.sr_net_loss) AS total_loss
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Catalog channel sales */
    catalog_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            SUM(cs.cs_net_profit) AS total_profit,
            0.0 AS total_loss
        FROM catalog_sales cs
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Catalog channel returns */
    catalog_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            0.0 AS total_profit,
            SUM(cr.cr_net_loss) AS total_loss
        FROM catalog_returns cr
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Web channel sales */
    web_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            SUM(ws.ws_net_profit) AS total_profit,
            0.0 AS total_loss
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Web channel returns */
    web_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            ib.ib_income_band_sk AS income_band_id,
            0.0 AS total_profit,
            SUM(wr.wr_net_loss) AS total_loss
        FROM web_returns wr
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY t.t_hour, ib.ib_income_band_sk
    ),
    /* Combine all channel aggregates */
    combined AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM store_returns_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM catalog_returns_agg
        UNION ALL
        SELECT * FROM web_sales_agg
        UNION ALL
        SELECT * FROM web_returns_agg
    )
SELECT
    hour_of_day,
    income_band_id,
    SUM(total_profit) AS total_profit,
    SUM(total_loss)   AS total_loss,
    SUM(total_profit) - SUM(total_loss) AS net_contribution
FROM combined
GROUP BY hour_of_day, income_band_id
ORDER BY hour_of_day, income_band_id
